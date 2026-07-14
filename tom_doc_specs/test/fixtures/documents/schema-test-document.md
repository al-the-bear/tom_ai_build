<!-- docspec: schema-test/1.0 -->
# Schema Test Document

This is a comprehensive test document that exercises all features of the
schema-test DocSpecs schema. It serves as a reference for md editor testing,
demonstrating every section type, form format, tag, code block, and validation
constraint defined in the schema.

## <!--[overview] --> Project Overview

This is the project overview section for the Schema Test Document. The purpose
of this document is to provide a comprehensive test fixture that exercises every
feature of the DocSpecs schema system.

Goals:
- Validate all section types are recognized by the editor
- Test form field extraction and inline editing
- Verify code block language detection
- Exercise tag validation and autocompletion
- Test nested subsection structure and position constraints

Scope: This document covers a fictional "TaskFlow" project with two components
(auth and api) to demonstrate the registry pattern, for-each linking, and
subsection declarations.

## <!--[config-001] --> Configuration

Environment: production
Version: 2.1.0
Owner: Tom Framework Team

## <!--[components-001] --> Component Registry

This section defines all components in the TaskFlow project.

### <!--[comp-auth] component-id=auth, targets=web,server --> Authentication

Handles user authentication, session management, and token validation.
Supports OAuth2 and API key authentication methods.

### <!--[comp-api] component-id=api, targets=web,server,mobile --> API Gateway

Central API gateway that routes requests, applies rate limiting, and
manages endpoint versioning across all client platforms.

## <!--[detail-auth] component-id=auth --> Authentication Component

Detailed specification for the authentication component.

### <!--[api-auth] --> Auth API Endpoints

API endpoints for the authentication component.

#### <!--[endpoint-login] --> Login

Description: Authenticates a user with credentials and returns a session token.
Supports both email/password and OAuth2 flows.
Method: POST
Path: /api/v1/auth/login
Auth: none

#### <!--[endpoint-logout] --> Logout

Description: Invalidates the current session token and clears server-side
session data.
Method: POST
Path: /api/v1/auth/logout
Auth: token

#### <!--[endpoint-refresh] --> Refresh Token

Description: Exchanges a valid refresh token for a new access token without
requiring re-authentication.
Method: POST
Path: /api/v1/auth/refresh
Auth: token

### <!--[model-auth] --> Auth Data Model

The authentication component uses the following data structures for managing
user sessions and credentials.

#### <!--[code-user-class] --> User Class

```dart
class User {
  final String id;
  final String email;
  final String passwordHash;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool isActive;

  User({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
    this.lastLogin,
    this.isActive = true,
  });
}
```

#### <!--[code-session-class] --> Session Class

```typescript
interface Session {
  id: string;
  userId: string;
  token: string;
  refreshToken: string;
  expiresAt: Date;
  createdAt: Date;
}
```

### <!--[tasks-auth] --> Auth Tasks

Tasks for the authentication component.

#### <!--[TASK-001] tags=critical --> Implement Login Flow

Assignee: Alice
Priority: critical
Status: approved
Due-date: 2026-04-15

Implement the full login flow including credential validation,
token generation, and session creation.

#### <!--[TASK-002] tags=high --> Add OAuth2 Support

Assignee: Bob
Priority: high
Status: draft

Add OAuth2 provider integration for Google and GitHub login.

### <!--[impl-auth] --> Auth Implementation Notes

The authentication system should use bcrypt for password hashing with a
cost factor of 12. JWT tokens should have a 15-minute expiry for access
tokens and 7-day expiry for refresh tokens. Rate limiting should be applied
to the login endpoint: max 5 attempts per minute per IP address.

Session storage should use Redis for fast lookups with automatic TTL-based
cleanup. All authentication events must be logged for audit purposes.

## <!--[detail-api] component-id=api --> API Gateway Component

Detailed specification for the API gateway component.

### <!--[api-gateway] --> Gateway API Endpoints

API endpoints managed by the API gateway.

#### <!--[endpoint-health] --> Health Check

Description: Returns the health status of the API gateway and all downstream
services it manages.
Method: GET
Path: /api/v1/health
Auth: none

#### <!--[endpoint-users] --> List Users

Description: Returns a paginated list of users. Supports filtering by status
and sorting by creation date.
Method: GET
Path: /api/v1/users
Auth: api-key

### <!--[model-api] --> Gateway Data Model

The API gateway uses route configuration and rate limit structures to
manage request routing and throttling.

#### <!--[code-route-config] --> Route Configuration

```dart
class RouteConfig {
  final String path;
  final String method;
  final String upstream;
  final bool requiresAuth;
  final int? rateLimitPerMinute;

  RouteConfig({
    required this.path,
    required this.method,
    required this.upstream,
    this.requiresAuth = true,
    this.rateLimitPerMinute,
  });
}
```

### <!--[tasks-api] --> Gateway Tasks

Tasks for the API gateway component.

#### <!--[TASK-003] tags=medium --> Implement Rate Limiting

Assignee: Charlie
Priority: medium
Status: review

Implement sliding-window rate limiting per API key with configurable
thresholds per endpoint.

### <!--[impl-api] --> Gateway Implementation Notes

The API gateway should use a reverse proxy pattern with configurable
routing rules stored in YAML configuration files. Rate limiting should
use a sliding window algorithm backed by Redis sorted sets.

Health checks should ping all registered upstream services and aggregate
their status into a single response. Circuit breaker pattern should be
implemented for upstream calls with configurable timeout thresholds.

## <!--[requirements-001] --> Requirements

All functional and non-functional requirements for the TaskFlow project.

### <!--[REQ-001] tags=critical --> Secure Authentication

The system must implement secure authentication using industry-standard
practices including bcrypt password hashing, JWT tokens with appropriate
expiry, and protection against brute force attacks via rate limiting.

### <!--[REQ-002] tags=high --> API Rate Limiting

The API gateway must enforce rate limiting per client with configurable
thresholds. Default rate limit: 100 requests per minute per API key.
Exceeded limits must return HTTP 429 with a Retry-After header.

### <!--[REQ-003] tags=medium --> Health Monitoring

All services must expose a health check endpoint that reports service
status, uptime, and dependency health. The gateway aggregates these
into a single dashboard-friendly response.

### <!--[REQ-004] tags=low --> API Versioning

The API gateway must support URL-based versioning (e.g., /api/v1/, /api/v2/)
with graceful deprecation notices for old versions via response headers.

## <!--[glossary-001] --> Glossary

### <!--[term-jwt] --> JWT

JSON Web Token — a compact, URL-safe token format used for authentication
and information exchange between parties.

### <!--[term-oauth2] --> OAuth2

Open Authorization 2.0 — an industry-standard protocol for authorization
that enables third-party applications to obtain limited access.

### <!--[term-rate-limit] --> Rate Limiting

A technique to control the rate of requests a client can make to an API
within a specified time window to prevent abuse.

## <!--[appendix-001] --> Appendix

### Reference Architecture

The TaskFlow system follows a microservices architecture with the API
gateway as the single entry point for all client requests.

### Technology Stack

- **Runtime:** Dart 3.x with Shelf for HTTP
- **Database:** PostgreSQL 15 with Redis for caching
- **Auth:** JWT with RS256 signing
- **Deployment:** Docker containers on Kubernetes
