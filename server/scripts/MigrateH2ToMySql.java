import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * One-time import tool for the file-backed H2 demo database.
 *
 * The MySQL business tables must be empty. This prevents accidentally mixing
 * demo data with records that were created after the MySQL switch.
 */
public final class MigrateH2ToMySql {
  private static final List<String> TABLES = List.of(
      "users",
      "tree_holes",
      "tree_members",
      "memories",
      "memory_embeddings",
      "time_capsules",
      "drift_bottles",
      "bottle_pickups",
      "bottle_resonances",
      "recall_cards");

  private MigrateH2ToMySql() { }

  public static void main(String[] args) throws Exception {
    String h2Url = require("ZHIYI_H2_URL");
    String mysqlUrl = require("ZHIYI_DB_URL");
    String mysqlUser = require("ZHIYI_DB_USERNAME");
    String mysqlPassword = require("ZHIYI_DB_PASSWORD");
    boolean replaceTarget = Boolean.parseBoolean(
        System.getenv().getOrDefault("ZHIYI_MIGRATION_REPLACE_TARGET", "false"));

    try (Connection h2 = DriverManager.getConnection(h2Url, "sa", "");
         Connection mysql = DriverManager.getConnection(mysqlUrl, mysqlUser, mysqlPassword)) {
      mysql.setAutoCommit(false);
      try {
        try (Statement statement = mysql.createStatement()) {
          statement.execute("SET FOREIGN_KEY_CHECKS = 0");
        }
        prepareMySql(mysql, replaceTarget);

        Map<String, Long> sourceCounts = new LinkedHashMap<>();
        for (String table : TABLES) {
          long count = copyTable(h2, mysql, table);
          sourceCounts.put(table, count);
          System.out.printf("Imported %s: %d row(s)%n", table, count);
        }

        verifyCounts(mysql, sourceCounts);
        try (Statement statement = mysql.createStatement()) {
          statement.execute("SET FOREIGN_KEY_CHECKS = 1");
        }
        mysql.commit();
        System.out.println("Migration completed and row counts verified.");
      } catch (Exception exception) {
        mysql.rollback();
        try (Statement statement = mysql.createStatement()) {
          statement.execute("SET FOREIGN_KEY_CHECKS = 1");
        } catch (SQLException ignored) {
          // Preserve the original error when the connection itself is unavailable.
        }
        throw exception;
      }
    }
  }

  private static String require(String name) {
    String value = System.getenv(name);
    if (value == null || value.isBlank()) {
      throw new IllegalArgumentException("Environment variable " + name + " is required.");
    }
    return value;
  }

  private static void prepareMySql(Connection mysql, boolean replaceTarget) throws SQLException {
    boolean hasExistingRows = false;
    for (String table : TABLES) {
      long rows = count(mysql, table);
      if (rows != 0) {
        hasExistingRows = true;
        if (!replaceTarget) {
          throw new IllegalStateException(
              "MySQL table '" + table + "' already contains " + rows
                  + " row(s). Migration stopped; no existing data was changed.");
        }
      }
    }

    if (hasExistingRows && replaceTarget) {
      try (Statement statement = mysql.createStatement()) {
        for (int index = TABLES.size() - 1; index >= 0; index--) {
          statement.executeUpdate("DELETE FROM " + TABLES.get(index));
        }
      }
      System.out.println("Existing MySQL business data was cleared before import.");
    }
  }

  private static long copyTable(Connection h2, Connection mysql, String table) throws SQLException {
    try (Statement sourceStatement = h2.createStatement();
         ResultSet sourceRows = sourceStatement.executeQuery("SELECT * FROM " + table)) {
      ResultSetMetaData metadata = sourceRows.getMetaData();
      List<String> sourceColumns = new ArrayList<>();
      for (int index = 1; index <= metadata.getColumnCount(); index++) {
        sourceColumns.add(metadata.getColumnLabel(index));
      }

      List<String> targetColumns = mysqlColumns(mysql, table);
      if (!normalized(sourceColumns).equals(normalized(targetColumns))) {
        throw new IllegalStateException(
            "Column mismatch in table '" + table + "'. The H2 and MySQL schemas must match.");
      }

      String placeholders = String.join(", ", java.util.Collections.nCopies(sourceColumns.size(), "?"));
      String sql = "INSERT INTO " + table + " (" + String.join(", ", sourceColumns)
          + ") VALUES (" + placeholders + ")";

      long copied = 0;
      try (PreparedStatement insert = mysql.prepareStatement(sql)) {
        while (sourceRows.next()) {
          for (int index = 1; index <= sourceColumns.size(); index++) {
            insert.setObject(index, sourceRows.getObject(index));
          }
          insert.addBatch();
          copied++;
          if (copied % 500 == 0) {
            insert.executeBatch();
          }
        }
        insert.executeBatch();
      }
      return copied;
    }
  }

  private static List<String> mysqlColumns(Connection mysql, String table) throws SQLException {
    List<String> columns = new ArrayList<>();
    try (Statement statement = mysql.createStatement();
         ResultSet rows = statement.executeQuery("SHOW COLUMNS FROM " + table)) {
      while (rows.next()) {
        columns.add(rows.getString("Field"));
      }
    }
    return columns;
  }

  private static List<String> normalized(List<String> columns) {
    return columns.stream().map(column -> column.toLowerCase(Locale.ROOT)).toList();
  }

  private static void verifyCounts(Connection mysql, Map<String, Long> sourceCounts) throws SQLException {
    for (Map.Entry<String, Long> entry : sourceCounts.entrySet()) {
      long targetCount = count(mysql, entry.getKey());
      if (targetCount != entry.getValue()) {
        throw new IllegalStateException(
            "Verification failed for table '" + entry.getKey() + "': expected "
                + entry.getValue() + ", found " + targetCount + ".");
      }
    }
  }

  private static long count(Connection connection, String table) throws SQLException {
    try (Statement statement = connection.createStatement();
         ResultSet result = statement.executeQuery("SELECT COUNT(*) FROM " + table)) {
      result.next();
      return result.getLong(1);
    }
  }
}
