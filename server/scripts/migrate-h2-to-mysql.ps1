param(
  [string]$SourceDatabase = "$env:USERPROFILE\.zhiyi\demo.mv.db",
  [switch]$ReplaceTarget
)

$ErrorActionPreference = 'Stop'
$serverRoot = Split-Path -Parent $PSScriptRoot
$workDirectory = Join-Path $serverRoot 'target\h2-migration'
$sourceCopy = Join-Path $workDirectory 'demo.mv.db'

if (-not (Test-Path -LiteralPath $SourceDatabase)) {
  throw "H2 source database was not found: $SourceDatabase"
}

@('ZHIYI_DB_URL', 'ZHIYI_DB_USERNAME', 'ZHIYI_DB_PASSWORD') | ForEach-Object {
  if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($_))) {
    throw "Set the environment variable $_ before running this script."
  }
}

$h2Jar = Get-ChildItem "$env:USERPROFILE\.m2\repository\com\h2database\h2" -Recurse -Filter 'h2-*.jar' |
  Sort-Object FullName -Descending |
  Select-Object -First 1
$mysqlJar = Get-ChildItem "$env:USERPROFILE\.m2\repository\com\mysql\mysql-connector-j" -Recurse -Filter 'mysql-connector-j-*.jar' |
  Sort-Object FullName -Descending |
  Select-Object -First 1

if ($null -eq $h2Jar -or $null -eq $mysqlJar) {
  throw 'Required H2 or MySQL JDBC driver was not found in the local Maven cache. Run mvn test once, then retry.'
}

New-Item -ItemType Directory -Force $workDirectory | Out-Null
Copy-Item -LiteralPath $SourceDatabase -Destination $sourceCopy -Force

$env:ZHIYI_H2_URL = "jdbc:h2:file:$($sourceCopy.Substring(0, $sourceCopy.Length - '.mv.db'.Length));MODE=MySQL;DATABASE_TO_LOWER=TRUE"
$env:ZHIYI_MIGRATION_REPLACE_TARGET = $ReplaceTarget.IsPresent.ToString().ToLowerInvariant()
$classesDirectory = Join-Path $workDirectory 'classes'
New-Item -ItemType Directory -Force $classesDirectory | Out-Null
$classPath = "$($h2Jar.FullName);$($mysqlJar.FullName)"

& javac -encoding UTF-8 -cp $classPath -d $classesDirectory (Join-Path $PSScriptRoot 'MigrateH2ToMySql.java')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& java -cp "$classesDirectory;$classPath" MigrateH2ToMySql
exit $LASTEXITCODE
