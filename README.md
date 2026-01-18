# Citizen Civic AI

A comprehensive civic engagement mobile application for Indian citizens to access constitutional knowledge, report civic issues, and build a local social civic community.

## 🌟 Features

### 🤖 AI-Powered Constitutional Assistant
- RAG-based chatbot trained on the Indian Constitution and related laws
- Multi-language support: English, Tamil (தமிழ்), and Hindi (हिन्दी)
- Document retrieval with source citations
- Contextual answers using LLM reasoning

### 📝 Complaint Reporting System
- Report civic issues with live images and GPS location
- Categories: Water leakage, Street light failure, Garbage, Law & Order, Road damage, and more
- Tag authorities using mentions (@police, @municipality, etc.)
- Location-based feeds and proximity queries
- Upvote and comment on complaints

### 🗺️ Google Maps Integration
- View complaints as markers on the map
- Filter by category
- Location-based discovery
- Heatmap visualization for administrators

### 👥 Social Community
- Post civic updates and discussions
- Follow other citizens and authorities
- Create polls for community decisions
- Comment and engage with posts

### 👮 Admin/Authority Panel
- Dashboard with complaint statistics
- Manage complaint status (Pending → In Progress → Resolved)
- Verify authority accounts
- Content moderation
- User management (Admin only)

## 🏗️ Architecture

### Backend (Python FastAPI)
```
backend/
├── app/
│   ├── api/v1/endpoints/    # REST API endpoints
│   ├── core/                # Configuration and security
│   ├── db/models/           # MongoDB document models
│   ├── schemas/             # Pydantic schemas
│   └── services/            # Business logic
├── Dockerfile
└── requirements.txt
```

### Frontend (Flutter)
```
frontend/
├── lib/
│   ├── core/                # Config, theme, services
│   ├── features/            # Feature modules
│   │   ├── auth/            # Authentication
│   │   ├── chat/            # AI Chatbot
│   │   ├── complaints/      # Complaint reporting
│   │   ├── community/       # Social features
│   │   ├── maps/            # Google Maps
│   │   └── admin/           # Admin dashboard
│   └── shared/              # Shared widgets and models
└── pubspec.yaml
```

## 🚀 Getting Started

### Prerequisites
- Python 3.11+
- Flutter 3.0+
- MongoDB 7.0+
- Docker (optional)

### Backend Setup

1. **Navigate to backend directory**
   ```bash
   cd backend
   ```

2. **Create virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # Linux/macOS
   # or
   .\venv\Scripts\activate  # Windows
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

5. **Run the server**
   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

6. **Access API documentation**
   - Swagger UI: http://localhost:8000/docs
   - ReDoc: http://localhost:8000/redoc

### Frontend Setup

1. **Navigate to frontend directory**
   ```bash
   cd frontend
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project
   - Add Android/iOS apps
   - Download and place configuration files
   - Enable Email/Password and Google Sign-In

4. **Configure Google Maps**
   - Get API key from Google Cloud Console
   - Add to Android and iOS configurations

5. **Run the app**
   ```bash
   flutter run
   ```

### Docker Setup

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## 📡 API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/register` | Register new citizen |
| POST | `/api/v1/auth/login` | Login with email/password |
| POST | `/api/v1/auth/admin/login` | Admin login (no signup) |
| POST | `/api/v1/auth/firebase` | Firebase authentication |

### Complaints
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/complaints` | List all complaints |
| POST | `/api/v1/complaints` | Create complaint |
| GET | `/api/v1/complaints/nearby` | Get nearby complaints |
| GET | `/api/v1/complaints/{id}` | Get complaint details |
| PUT | `/api/v1/complaints/{id}/status` | Update status (authority) |
| POST | `/api/v1/complaints/{id}/upvote` | Toggle upvote |

### Chat
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/chat/sessions` | Create chat session |
| GET | `/api/v1/chat/sessions` | List sessions |
| POST | `/api/v1/chat/sessions/{id}/messages` | Send message |
| GET | `/api/v1/chat/languages` | Get supported languages |

### Community
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/community/posts` | List posts |
| POST | `/api/v1/community/posts` | Create post |
| GET | `/api/v1/community/feed` | Get personalized feed |
| POST | `/api/v1/community/users/{id}/follow` | Follow user |

### Admin
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/admin/dashboard` | Get dashboard stats |
| GET | `/api/v1/admin/users` | List users |
| PUT | `/api/v1/admin/users/{id}/role` | Update user role |
| GET | `/api/v1/admin/complaints/heatmap` | Get heatmap data |

## 🔐 User Roles

| Role | Description | Signup Allowed |
|------|-------------|----------------|
| Citizen | Default role for registered users | ✅ Yes |
| Authority | Government officials | ✅ Yes (requires verification) |
| Admin | Full system access | ❌ No (login only) |

## 🌐 Supported Languages

- **English** (en) - Default
- **Tamil** (ta) - தமிழ்
- **Hindi** (hi) - हिन्दी

## 🛠️ Technology Stack

### Backend
- **FastAPI** - Modern Python web framework
- **MongoDB** - Document database with Beanie ODM
- **Firebase Admin** - Authentication
- **LangChain** - RAG implementation
- **ChromaDB** - Vector database

### Frontend
- **Flutter** - Cross-platform mobile framework
- **BLoC** - State management
- **Go Router** - Navigation
- **Google Maps Flutter** - Map integration
- **Firebase Auth** - Authentication

## 📱 Screenshots

*Coming soon*

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Indian Constitution documents
- Open source community
- Flutter and FastAPI teams