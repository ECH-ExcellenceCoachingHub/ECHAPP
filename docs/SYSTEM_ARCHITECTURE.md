# ExcellenceCoachingHub - Complete System Architecture

## System Overview

ExcellenceCoachingHub is a comprehensive e-learning platform that provides a complete solution for online education with the following key features:

- **Cross-platform mobile and desktop app** (Flutter)
- **Secure backend API** (Node.js/Express)
- **Protected video streaming** (Cloudflare Stream)
- **Mobile money payments** (MTN MoMo, Airtel Money)
- **Comprehensive learning management** (courses, exams, progress tracking)

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        FRONTEND (Flutter)                        │
├─────────────────────────────────────────────────────────────────┤
│  Authentication  │  Course Browsing  │  Video Player  │  Exams  │
│       UI         │       UI          │      UI        │   UI    │
├─────────────────────────────────────────────────────────────────┤
│              Riverpod State Management                          │
├─────────────────────────────────────────────────────────────────┤
│                   HTTP API Client                               │
└─────────────────────────┬───────────────────────────────────────┘
                          │ HTTPS
┌─────────────────────────▼───────────────────────────────────────┐
│                     BACKEND (Node.js)                            │
├─────────────────────────────────────────────────────────────────┤
│  Auth Routes  │  Course Routes  │  Video Routes  │  Exam Routes │
├─────────────────────────────────────────────────────────────────┤
│              Express.js Middleware & Controllers                │
├─────────────────────────────────────────────────────────────────┤
│        MongoDB (Mongoose)  │  Cloudflare Stream API             │
└─────────────────────────────────────────────────────────────────┘
```

## Technology Stack

### Frontend (Flutter)
- **Framework**: Flutter 3.x
- **State Management**: Riverpod
- **Navigation**: Go Router
- **HTTP Client**: http package
- **Storage**: Shared Preferences + Secure Storage
- **Video**: video_player + chewie
- **UI**: Material Design 3

### Backend (Node.js)
- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose
- **Authentication**: JWT (access + refresh tokens)
- **File Storage**: AWS S3 with streaming capability
- **Security**: bcrypt, helmet, CORS

## Data Flow

### 1. User Authentication Flow
```
Flutter App → Login Screen → HTTP POST /api/auth/login 
    → Backend validates credentials → Returns JWT tokens
    → Flutter stores tokens securely → User authenticated
```

### 2. Course Access Flow
```
Flutter App → Course List → HTTP GET /api/courses
    → Backend returns published courses
    → User selects course → HTTP GET /api/courses/{id}/details
    → Backend checks enrollment → Returns course details
```

### 3. Video Streaming Flow
```
Flutter App → Lesson → HTTP GET /api/videos/{lessonId}/stream-url
    → Backend verifies enrollment → Generates signed AWS S3 URL
    → Flutter receives signed URL → Video player loads content
    → Video expires after 1 hour (security)
```

### 4. Payment Flow
```
Flutter App → Course Details → Check if paid course
    → User clicks Enroll → HTTP POST /api/payments/initiate
    → Backend creates payment record → Returns transaction ID
    → Flutter opens mobile money app → User completes payment
    → HTTP POST /api/payments/verify → Backend confirms payment
    → User can now access course content
```

### 5. Exam Flow
```
Flutter App → Course Exam → HTTP GET /api/exams/{courseId}
    → Backend returns available exams → User selects exam
    → HTTP GET /api/exams/{examId}/questions → Get exam questions
    → User answers questions → HTTP POST /api/exams/{examId}/submit
    → Backend auto-grades → Returns results and pass/fail status
```

## Security Implementation

### Video Security (Critical)
- All videos stored privately on Cloudflare Stream
- No public video URLs
- Backend generates signed URLs with 10-minute expiration
- Each URL request validates:
  - User authentication
  - Course enrollment
  - Video access permissions

### Authentication Security
- JWT tokens with short expiration (15 minutes)
- Refresh tokens for session management
- Password hashing with bcrypt
- Role-based access control
- Secure token storage in Flutter Secure Storage

### Data Protection
- HTTPS encryption for all API communications
- Input validation and sanitization
- Rate limiting on authentication endpoints
- Proper CORS configuration
- Environment-based configuration

## Database Schema Relationships

```
User (1) ──────────── (Many) Enrollment
  │                          │
  │                          ▼
  │                     Course (1) ──────────── (Many) Section
  │                          │                          │
  │                          ▼                          ▼
  │                     Payment (Many)             Lesson (Many)
  │                          │
  │                          ▼
  │                     Exam (1) ──────────── (Many) Question
  │                          │
  │                          ▼
  └──────────────────── Result (Many)
```

## API Endpoints Summary

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/refresh-token` - Token refresh
- `GET /api/auth/profile` - User profile
- `POST /api/auth/logout` - User logout

### Courses
- `GET /api/courses` - List all courses
- `GET /api/courses/{id}` - Get course details
- `GET /api/courses/{id}/details` - Detailed course info

### Enrollments
- `POST /api/enrollments` - Enroll in course
- `GET /api/enrollments/my-courses` - User's courses
- `PUT /api/enrollments/{id}/progress` - Update progress

### Videos
- `GET /api/videos/{lessonId}/stream-url` - Get signed video URL

### Exams
- `GET /api/exams/{courseId}` - Course exams
- `POST /api/exams/{examId}/submit` - Submit exam
- `GET /api/exams/{examId}/results` - Exam results

### Payments
- `POST /api/payments/initiate` - Start payment
- `POST /api/payments/verify` - Verify payment

### Admin
- `GET /api/admin/students` - All students
- `GET /api/admin/course-stats` - Course analytics
- `GET /api/admin/payment-stats` - Payment analytics

## Deployment Architecture

### Production Setup
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Load Balancer  │    │   Application    │    │   MongoDB       │
│   (Nginx/Cloud)  │◄──►│     Servers      │◄──►│   Database      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                    ┌─────────────────────────┐
                    │   Cloudflare Stream     │
                    │      (Video Storage)    │
                    └─────────────────────────┘
```

### Mobile App Distribution
- **Android**: Google Play Store
- **iOS**: Apple App Store
- **Desktop**: Direct download or package managers

## Development Workflow

### Backend Development
1. Set up MongoDB locally or use MongoDB Atlas
2. Configure environment variables
3. Run `npm run dev` for development server
4. Test APIs with Postman or curl

### Frontend Development
1. Ensure backend is running
2. Update API base URL in config
3. Run `flutter run` for development
4. Test on multiple platforms

### Testing Strategy
- Unit tests for business logic
- Integration tests for API endpoints
- Widget tests for Flutter components
- End-to-end testing for critical user flows

## Monitoring and Maintenance

### Backend Monitoring
- Application performance monitoring
- Database performance metrics
- Error tracking and logging
- API response time monitoring

### Frontend Monitoring
- Crash reporting
- Performance metrics
- User engagement analytics
- Platform-specific metrics

## Scaling Considerations

### Horizontal Scaling
- Load balancer for multiple backend instances
- Database sharding for large datasets
- AWS S3 for file storage and distribution
- Potential future addition of CloudFront CDN

### Performance Optimization
- Database indexing
- API response caching
- Image optimization
- Video compression and adaptive streaming

## Future Roadmap

### Short-term (3-6 months)
- Certificate generation system
- Offline content download
- Push notifications
- Social sharing features

### Medium-term (6-12 months)
- Instructor portal
- Advanced analytics dashboard
- Multi-language support
- AI-powered learning recommendations

### Long-term (12+ months)
- Virtual classroom features
- Gamification elements
- Mobile app widgets
- Integration with learning standards (SCORM, xAPI)

This architecture provides a solid foundation for a scalable, secure, and feature-rich e-learning platform that can grow with ExcellenceCoachingHub's needs.