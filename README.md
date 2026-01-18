# Voce Backend API

This is the backend API for **Voce**, a voice-first note-taking application.

## Overview
Voce allows users to record voice notes, transcribe them to text, and forward them to custom webhooks. This Rails API handles:
-   User voice note storage.
-   Speech-to-Text (STT) processing/integration.
-   Webhook management.
-   Dispatching note payloads to user-defined webhooks.

## Tech Stack
-   **Framework**: Ruby on Rails 8 (API Mode)
-   **Database**: PostgreSQL
-   **Deployment**: Kamal (Docker) on Hetzner VPS

## Setup & Running
1.  **Install Dependencies**:
    ```bash
    bundle install
    ```
2.  **Database Setup**:
    ```bash
    bin/rails db:prepare
    ```
3.  **Run Server**:
    ```bash
    bin/rails s
    ```

## Development Guidelines
-   **Speed First**: We are prioritizing feature delivery.
-   **No Tests**: Automated tests are skipped for now to increase velocity.
-   **Clean Code**: Maintain standard Rails conventions and security best practices despite the speed focus.

## Deployment
Deployment is handled via **Kamal**.
Refer to `config/deploy.yml` for configuration.
