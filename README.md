# Microservices Architecture

A containerized microservices system built with **Spring Boot, Flask/Python, Apache Kafka, Redis, MySQL, Docker Compose, and Kong API Gateway**.

The project demonstrates API Gateway routing, custom authentication, event-driven communication, service-level databases, Redis caching, and AI-powered expense extraction.

---

## 🏗️ System Architecture

![Microservices System Architecture](/Users/roshanjaiswal/Downloads/Architecture.png)

 

## 🚀 Main Components

| Component | Port | Technology | Responsibility |
|---|---:|---|---|
| **Kong API Gateway** | `8000` | Kong + Lua | API routing and custom authentication |
| **Auth Service** | `9898` | Spring Boot | Signup, login, authentication and user event production |
| **User Service** | `9810` | Spring Boot | User profile and user management |
| **Expense Service** | `9820` | Spring Boot | Expense management and Kafka event consumption |
| **Data Science Service** | `8010` | Flask/Python | Bank SMS processing and AI expense extraction |
| **Apache Kafka** | `9092` / `29092` | Kafka | Asynchronous event communication |
| **MySQL** | `3306` | MySQL 8.3 | Persistent service data |
| **Redis** | `6379` | Redis 7 Alpine | Caching |

---

# 🔄 Event-Driven Communication

The system uses Apache Kafka to decouple services.

## 1. User Creation Flow

When a client performs signup through Kong:

```text
Client
   │
   ▼
Kong API Gateway
   │
   ▼
Auth Service
   │
   │ Publish
   ▼
Kafka
   │
   │ user_service topic
   ▼
User Service
   │
   ▼
userservice MySQL
```

### `user_service` event

Auth Service produces user information such as:

```json
{
  "firstName": "Roshan",
  "lastName": "Jaiswal",
  "email": "roshan@example.com",
  "phoneNumber": 9876543210,
  "userId": "123e4567-e89b-12d3-a456-426614174000",
  "profilePic": "https://example.com/profile.jpg"
}
```

The User Service consumes the event and performs the required user/profile operations.

---

## 2. AI Expense Extraction Flow

When a client sends a bank SMS/message through Kong:

```text
Client
   │
   ▼
Kong API Gateway
   │
   ▼
Data Science Service
   │
   ▼
Groq LLM
   │
   │ Extracts
   │ amount
   │ currency
   │ merchant
   │ user_id
   ▼
Kafka
   │
   │ expense_service topic
   ▼
Expense Service
   │
   ▼
expenseservice MySQL
```

### `expense_service` event

The Data Science Service produces:

```json
{
  "amount": "29000",
  "currency": "INR",
  "merchant": "dip Coffee shop",
  "user_id": "d0936019-d4be-454e-bddb-a8e19ad580b6"
}
```

The Expense Service consumes the event and stores/processes the expense.

---

# ⚡ Redis Caching

Redis is used by:

- **User Service** — user data caching
- **Expense Service** — expense data caching
- **Data Science Service** — LLM response caching

Redis is **not used by the Auth Service**.

```text
                    Redis :6379
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              ▼
     User Service   Expense Service   DS Service
      user cache    expense cache    LLM cache
```

The Data Science Service can cache an extracted expense result so repeated processing of the same user/message can avoid unnecessary LLM calls during the cache TTL.

---

# 🗄️ Database Architecture

Each business service has its own MySQL database:

```text
MySQL :3306
│
├── authservice
│   └── Authentication / user credentials
│
├── userservice
│   └── User profiles / user data
│
└── expenseservice
    └── Expense transactions / expense data
```

This keeps service data separated and avoids making every service directly dependent on a shared business database.

---

# 🌐 Kong API Gateway

Kong provides a single entry point for clients.

```text
Client
  │
  ▼
Kong :8000
  │
  ├── /auth/*      → Auth Service :9898
  ├── /users/*     → User Service :9810
  ├── /expenses/*  → Expense Service :9820
  └── /ds/*        → Data Science Service :8010
```

The project also includes a custom Lua authentication plugin.

---

# 🔐 Authentication

The request flow is:

```text
Client
  │
  ▼
Kong
  │
  ▼
Custom Authentication Plugin
  │
  ▼
Protected Microservice
```

Authentication-related operations are handled by the Auth Service.

---

# 🤖 Data Science Service

The Data Science Service is implemented using Flask/Python.

Responsibilities:

- Receive bank SMS/transaction messages
- Validate/process the message
- Use Groq LLM for structured expense extraction
- Cache LLM results in Redis
- Publish extracted expense data to Kafka
- Provide health/developer endpoints

Example extracted structure:

```json
{
  "amount": "29000",
  "currency": "INR",
  "merchant": "dip Coffee shop",
  "user_id": "..."
}
```

---

# 📨 Kafka Topics

### `user_service`

Produced by:

```text
Auth Service
```

Consumed by:

```text
User Service
```

Purpose:

```text
Synchronize user information from authentication
to the User Service asynchronously.
```

### `expense_service`

Produced by:

```text
Data Science Service
```

Consumed by:

```text
Expense Service
```

Purpose:

```text
Transfer AI-extracted expense information
to the Expense Service asynchronously.
```

---

# 📡 API Endpoints

## Auth Service — `9898`

| Method | Endpoint | Purpose |
|---|---|---|
| POST | `/signup` | Register user |
| POST | `/login` | Login |
| GET | `/health` | Health check |
| GET | `/ping` | Ping |
| GET | `/developer` | Developer information |

## User Service — `9810`

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/getUser` | Get user |
| POST | `/createUpdate` | Create/update user |
| GET | `/health` | Health check |
| GET | `/developer` | Developer information |

## Expense Service — `9820`

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/getExpense` | Get expenses |
| POST | `/addExpense` | Add expense |
| GET | `/health` | Health check |
| GET | `/developer` | Developer information |

## Data Science Service — `8010`

| Method | Endpoint | Purpose |
|---|---|---|
| POST | `/v1/ds/message` | Process bank SMS/message |
| GET | `/api/v1/developer` | Developer information |
| GET | `/health` | Health check |

---

# 🐳 Docker Architecture

The complete application is containerized using Docker Compose.

```text
docker-compose.yml
│
├── kong-service
├── authservice
├── userservice
├── expenseservice
├── dsservice
├── kafka
├── mysql
└── redis
```

### Kafka networking

Kafka exposes two listeners:

```text
Internal Docker network → kafka:29092
External host access    → localhost:9092
```

Microservices communicate with Kafka using:

```text
kafka:29092
```

---

# ⚙️ Environment Configuration

Create a `.env` file:

```env
GROQ_API_KEY=your_groq_api_key
```

Do not commit real API keys or secrets to GitHub.

---

# ▶️ Running the Project

### 1. Clone

```bash
git clone https://github.com/CodeCortex/microservice.git
cd microservice
```

### 2. Configure environment

```bash
cp .env.example .env
```

Add your required environment variables.

### 3. Start the complete system

```bash
docker compose up -d
```

### 4. Check containers

```bash
docker compose ps
```

### 5. View logs

```bash
docker compose logs -f
```

Or for an individual service:

```bash
docker compose logs -f dsservice
docker compose logs -f userservice
docker compose logs -f expenseservice
docker compose logs -f authservice
```

### 6. Stop

```bash
docker compose down
```

To also remove persistent Docker volumes:

```bash
docker compose down -v
```

> `docker compose down -v` deletes the Docker volumes used by MySQL/Redis, so use it only when you intentionally want to remove persisted local data.

---

# 📁 Project Structure

```text
microservice/
│
├── docker-compose.yml
├── kong.yml
├── .env
├── .gitignore
├── README.md
│
├── kong/
│   └── plugins/
│       └── custom-auth/
│           ├── handler.lua
│           └── schema.lua
│
├── mysql/
│   └── init.sql
│
├── authService/
│   └── ...
│
├── userService/
│   └── ...
│
├── expenseService/
│   └── ...
│
└── dsService/
    └── ...
```

---

# 🧠 Technologies Used

### Backend

- Java 21
- Spring Boot
- Python 3
- Flask
- Pydantic

### Messaging

- Apache Kafka

### Database

- MySQL 8.3

### Caching

- Redis 7

### AI

- Groq LLM
- `openai/gpt-oss-20b`

### API Gateway

- Kong
- Custom Lua authentication plugin

### Infrastructure

- Docker
- Docker Compose

---

# 🎯 Key Engineering Concepts Demonstrated

- Microservices architecture
- API Gateway pattern
- Custom authentication plugin
- Event-driven architecture
- Kafka producer/consumer pattern
- Asynchronous service communication
- Database-per-service approach
- Redis caching
- AI/LLM integration
- Docker containerization
- Internal/external Kafka networking
- Environment-based configuration
- Service health endpoints
- Separation of responsibilities between services

---

# 🔄 End-to-End Example

### User Signup

```text
Client
  ↓
Kong
  ↓
Auth Service
  ↓
Publish user_service
  ↓
Kafka
  ↓
User Service
  ↓
userservice MySQL
```

### Expense from Bank SMS

```text
Client
  ↓
Kong
  ↓
Data Science Service
  ↓
Redis cache
  │
  ├── HIT → cached result
  │
  └── MISS → Groq LLM
                ↓
              Redis
                ↓
              Kafka
                ↓
        expense_service topic
                ↓
        Expense Service
                ↓
        expenseservice MySQL
```

---

# 📌 Architecture Highlights

The project separates responsibilities across independent services while using **Kong for synchronous API routing**, **Kafka for asynchronous event-driven communication**, **Redis for caching**, and **MySQL for persistent storage**.

The two primary event flows are:

```text
Auth Service
     │
     ▼
user_service topic
     │
     ▼
User Service
```

and:

```text
Data Science Service
     │
     ▼
expense_service topic
     │
     ▼
Expense Service
```

This design demonstrates how independently deployable services can communicate without tightly coupling their internal implementations.

---

## 👨‍💻 Developer

**Roshan Jaiswal — CodeCortex**

GitHub: https://github.com/CodeCortex  
LinkedIn: https://www.linkedin.com/in/codecortex/  
Instagram: https://www.instagram.com/codecortexx/

---

## 📄 License

This project is intended for learning, portfolio, and demonstration purposes.
