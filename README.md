# Date · 植忆 🌱

> **Let memories grow.**

Date (植忆) is an open-source HarmonyOS application for preserving everyday memories in a more meaningful and human way.

Instead of treating memories as isolated posts in an endless feed, Date turns them into something that can grow over time. Text, photos, moods, people, and moments become part of a living memory tree — a personal space for remembering life and a shared space for preserving meaningful days with others.

This project started as a creative idea from a group of university students. What began as a course project gradually became something we wanted to continue building beyond the classroom.

We are still learning, experimenting, and improving Date, and we hope to grow it together with the open-source community.

---

## ✨ Why Date?

Most digital memories eventually disappear into photo galleries, chat histories, or social media timelines.

We wanted to explore a different idea:

**What if memories could grow instead of simply accumulating?**

Date uses the metaphor of planting and growing to make recording life feel more intentional.

A memory is not just another post.

It becomes part of your tree.

And some memories are better when they are preserved together.

---

## 🌿 Features

### 🌳 Memory Tree

Your memories gradually form a personal memory tree.

Instead of browsing an ordinary chronological feed, Date gives memories a visual and emotional structure that grows with you.

### 📝 Capture Everyday Moments

Record a memory with:

- Text
- Photos
- Mood
- Date and time

Small moments are often the easiest to forget. Date is designed to make preserving them simple.

### 💚 Mood Memories

Each memory can carry an emotional state.

Over time, your memory collection becomes not only a record of **what happened**, but also a record of **how those moments felt**.

### 🕳️ Tree Holes

Create a private shared space — a **Tree Hole (树洞)** — and invite people using an invitation code.

Members of a Tree Hole can preserve memories together, making it useful for:

- Close friends
- Couples
- Families
- Travel companions
- Small communities

The goal is not to build another public social network.

It is to create smaller, more meaningful spaces for shared memories.

### 🕰️ Common Day

**Common Day (共同一天)** connects everyone's memories from the same day through an hourly timeline.

Choose a date and an hour, then see what different people were experiencing at that moment.

A day that might otherwise disappear becomes a shared timeline built from multiple perspectives.

---

## 📱 Screenshots

> Screenshots and demo videos are coming soon.

<!--
You can later place screenshots in an assets folder:

<p align="center">
  <img src="assets/home.png" width="220" />
  <img src="assets/tree.png" width="220" />
  <img src="assets/common-day.png" width="220" />
</p>
-->

---

## 🏗️ Architecture

Date currently consists of two main parts:

```text
Date/
├── AppScope/                 # HarmonyOS application resources
├── entry/                    # HarmonyOS client
│   └── src/main/ets/
│       ├── components/
│       ├── constants/
│       ├── models/
│       ├── pages/
│       ├── repositories/
│       ├── services/
│       └── viewmodels/
│
└── server/                   # Backend service
    ├── scripts/
    ├── src/
    └── pom.xml
```

The client follows a structured separation between UI pages, view models, repositories, services, and data models.

The backend provides authentication, memory storage, image uploads, shared Tree Holes, and Common Day APIs.

---

## 🛠️ Tech Stack

### HarmonyOS Client

- HarmonyOS
- ArkTS
- ArkUI
- DevEco Studio
- HTTP-based backend communication
- Local token storage
- HarmonyOS image picker

### Backend

- Java 21
- Spring Boot 3.5
- Spring Security
- JWT authentication
- Spring Data JPA
- MySQL 8
- Flyway
- H2 for local demo/testing
- OpenAPI / Swagger
- Maven

---

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone https://<repository-url>/Date.git
cd Date
```

---

## 🖥️ Backend Setup

### Requirements

Make sure you have:

- Java 21
- Maven 3.9+
- MySQL 8

### Option A — Quick local demo

The backend provides a demo profile using a local H2 database:

```bash
cd server
mvn spring-boot:run "-Dspring-boot.run.profiles=demo"
```

The API will run on:

```text
http://localhost:8080
```

Swagger UI:

```text
http://localhost:8080/swagger-ui.html
```

### Option B — MySQL

Create the local database using:

```text
server/scripts/create-local-db.sql
```

Then configure the following environment variables:

```text
ZHIYI_DB_URL
ZHIYI_DB_USERNAME
ZHIYI_DB_PASSWORD
ZHIYI_JWT_SECRET
```

Example:

```powershell
$env:ZHIYI_DB_URL='jdbc:mysql://127.0.0.1:3306/zhiyi?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Shanghai'
$env:ZHIYI_DB_USERNAME='zhiyi_app'
$env:ZHIYI_DB_PASSWORD='your-password'
$env:ZHIYI_JWT_SECRET='your-secure-random-secret'
```

Start the backend:

```bash
mvn spring-boot:run
```

Flyway will automatically initialize the database schema.

---

## 📱 HarmonyOS Client Setup

1. Open the project in **DevEco Studio**.
2. Configure HarmonyOS signing if required.
3. Start the backend.
4. Configure the backend endpoint in:

```text
entry/src/main/ets/constants/ApiConfig.ets
```

For physical-device debugging, make sure your computer and HarmonyOS device are connected to the same network.

Set the backend URL to your computer's local IP, for example:

```text
http://192.168.x.x:8080
```

Then build and run the `entry` module on your HarmonyOS device or emulator.

---

## 🔌 Main API Areas

The backend currently provides APIs for:

### Authentication

```text
POST /api/auth/register
POST /api/auth/login
GET  /api<REDACTED_LOCAL_PATH>
```

### Memories

```text
GET    /api/memories
POST   /api/memories
GET    /api/memories/{id}
PATCH  /api/memories/{id}
DELETE /api/memories/{id}
```

### Images

```text
POST /api/files/images
```

### Tree Holes

```text
POST /api/tree-holes
GET  /api/tree-holes
POST /api/tree-holes/join
```

### Shared Memories

```text
GET /api/tree-holes/{id}/members
GET /api/tree-holes/{id}/memories
GET /api/tree-holes/{id}/common-day?date=YYYY-MM-DD
```

---

## 🧪 Testing

Backend tests can be run with:

```bash
cd server
mvn test
```

The current test suite covers several important flows including authentication protection, registration conflicts, Tree Hole invitation behavior, member isolation, and Common Day queries.

---

## 🎓 Our Story

Date started as a university course project.

We are students, and the original goal was simply to turn an idea into a working application.

But while building it, we became interested in a larger question:

> How can software help people preserve ordinary moments without turning those moments into content for a public social feed?

That question became the foundation of Date.

Although the course gave us the reason to start, we do not want the project to end with the course.

We are open-sourcing Date because we want to keep learning, improve the engineering behind it, and allow other developers to experiment with the idea as well.

We hope Date can become both a useful application and an approachable reference project for developers interested in building human-centered experiences on HarmonyOS.

---

## 🤖 Building with Codex

As student developers, our time, experience, and development resources are limited.

We hope to use Codex to help us continue developing Date beyond its original course-project scope — including:

- Refactoring and improving the existing codebase
- Finding and fixing bugs
- Expanding automated tests
- Improving API and project documentation
- Reviewing frontend/backend changes
- Improving architecture and maintainability
- Exploring new memory interaction ideas
- Making the project easier for new contributors to understand

Our goal is not simply to use AI to generate more code.

We want to use Codex as a tool to help us learn better software engineering practices while turning a student prototype into a more reliable and sustainable open-source project.

---

## 🗺️ Roadmap

Date is still at an early stage.

Some areas we would like to explore next include:

- [ ] Improve Memory Tree visualization
- [ ] Better photo and media experiences
- [ ] Memory search and filtering
- [ ] Memory tags
- [ ] More expressive mood visualization
- [ ] Better Common Day interactions
- [ ] Notifications and memory reminders
- [ ] Improved privacy controls
- [ ] Data export and backup
- [ ] More automated tests
- [ ] CI/CD
- [ ] Better documentation
- [ ] Internationalization
- [ ] Accessibility improvements

Ideas and contributions are welcome.

---

## 🤝 Contributing

Date is a student-led project, and contributions of all sizes are welcome.

You can help by:

- Reporting bugs
- Suggesting features
- Improving documentation
- Improving UI/UX
- Adding tests
- Refactoring code
- Improving accessibility
- Opening pull requests

If you are interested in contributing, feel free to open an Issue first to discuss your idea.

We are learning too, so beginners are welcome.

---

## 🌱 Project Philosophy

Date is built around a simple belief:

> **Not every meaningful moment needs an audience. Some moments simply deserve to be remembered.**

We want to build technology that helps people preserve those moments — privately, intentionally, and sometimes together.

---

## ⭐ Support

If you find Date interesting, consider giving the repository a star.

It helps us know that this idea is worth continuing.

Contributions, suggestions, and discussions are equally appreciated.

---

## 📄 License

Date is open-source software licensed under the **MIT License**.

Copyright © 2026 Date Contributors.

You are free to use, modify, and distribute this project under the terms of the MIT License.

---

<p align="center">
  <b>Date · 植忆</b><br/>
  Let memories grow. 🌱
</p>
