# Tincan Deploy

Tincan is a financial aggregation tool that connects to your credit card, bank, and investment accounts to provide a unified view of your spending habits. Transactions are automatically categorized using AI, or you can define custom categorization rules. For added flexibility, Tincan also supports manual uploads of statements in PDF or CSV format, parsing transactions for seamless analysis. Gain insights into your financial trends and allocate your money wisely with Tincan.

`tincan-deploy` is the central repository for deploying the **Tincan Application**. This repository orchestrates the deployment of the backend, frontend, and reverse proxy services using prebuilt Docker images. By design, `tincan-deploy` avoids pulling source code directly, relying only on Docker images from a container registry for simplified and efficient production deployment.

---

## Repository Structure

This repository includes the following key files:

### 1. `docker-compose.yml`
Defines the services and their configurations for the Tincan Application:
- **db**: PostgreSQL database for storing financial data.
- **backend**: Rails-based backend application.
- **frontend**: React TypeScript frontend.
- **nginx**: Reverse proxy for routing requests to the appropriate services.

### 2. `.env`
Holds environment variables required for deployment:
- `DOCKER_HUB_USERNAME`: Docker Hub username for pulling images.
- `PG_PASSWORD`: PostgreSQL database password.
- `PG_USER`: PostgreSQL database username.
- `RAILS_MASTER_KEY`: Rails master key for encrypted credentials.

---

## Deployment Workflow

1. **Prebuilt Images**:
   The following repositories build and push Docker images to a registry:
   - [Tincan Backend](https://github.com/pdayboch/tincan-backend): Rails backend.
   - [Tincan Frontend](https://github.com/pdayboch/tincan-frontend): React TypeScript frontend.
   - [Tincan Nginx](https://github.com/pdayboch/tincan-nginx): Reverse proxy configuration.

2. **Pull Images**:
   When deploying, `tincan-deploy` pulls the latest images from the registry specified by `DOCKER_HUB_USERNAME`.

3. **Run Services**:
   `docker-compose` brings up all services in a single network with properly configured dependencies.

---
## Getting Started

### Prerequisites

1. Clone the [Backend](https://github.com/pdayboch/tincan-backend), [Frontend](https://github.com/pdayboch/tincan-frontend), and [Nginx](https://github.com/pdayboch/tincan-nginx) repositories onto your development server.

2. In each of these project directories, create an .env file and add an entry for DOCKER_HUB_USERNAME

```
#.env
DOCKER_HUB_USERNAME=<user dockerhub username>
```

Then follow the project specific instructions:

#### Backend
1. Generate a Rails master key and record this for a later step.
2. Run `./build_and_push.sh`. This will build and push the Rails backend image up to your registry. 

#### Frontend
1. Update the base API URL if necessary according to the **Domain Configuration** section below.
2. Run `./build_and_push.sh`. This will build and push the Next.js frontend image up to your registry.

#### nginx
1. Update the nginx.conf if necessary according to the **Domain Configuration** section below.
2. Run `./build_and_push.sh`. This will build and push the Next.js frontend image up to your registry.

### Deploy server
1. Ensure Docker and Docker Compose are installed on the production server (the server hosting the application).
2. Set up environment variables by creating a `.env` file in the root of this repository.

Example `.env` file:

```env
DOCKER_HUB_USERNAME=mydockerhubusername
PG_PASSWORD=securepassword
PG_USER=dbuser
RAILS_MASTER_KEY=supersecurekey
```

### Domain Configuration

Since this application is self-hosted and not publicly available on the internet, you need to configure access to `tincan.com` and `api.tincan.com`. You can choose one of the following options:

1. Router DNS Configuration:

   Configure your home router to resolve tincan.com and api.tincan.com to the local IP address of the server hosting the application. This is recommended as it allows all devices on the network to access the application using memorable domain names.

2. Update `/etc/hosts`entries on devices accessing the application for `tincan.com` and `api.tincan.com` to your local `/etc/hosts` file:

   ```
   <application server> tincan.com
   <application server> api.tincan.com

   # <application server> is the local IP of your server running the docker-compose.
   # Ex:
   192.168.1.2 tincan.com
   192.168.1.2 api.tincan.com
   ```

3. **Frontend API Configuration**:
   If you cannot use the above options, update the root API URL in the frontend code to use `127.0.0.1`:
   Edit `tincan-frontend/src/utils/api-utils.ts`:

   ```javascript
   const API_URL = "http://127.0.0.1";
   ```
   as well as update the **tincan-nginx/nginx.conf** to replace `server_name` *tincan.com* and *api.tincan.com* with *127.0.0.1*.
   
   Then, run ./build_and_push.sh from tincan-frontend and tincan-nginx repositories to update your images.

### Steps

1. Clone the `tincan-deploy` repository:

   ```bash
   git clone https://github.com/yourorg/tincan-deploy.git
   cd tincan-deploy
   ```

2. Start the services:

   ```bash
   docker-compose up -d
   ```

3. Verify all services are running:

   ```bash
   docker-compose ps
   ```

4. Access the application depending on how you configured the domain above:

   - **Website**: [http://tincan.com](http://tincan.com) | [http://127.0.0.1](http://127.0.0.1)
   - **API**: [http://api.tincan.com](http://api.tincan.com) | [http://api.127.0.0.1](http://api.127.0.0.1)
   - or use the local IP of the server such as 192.168.x.x or 10.x.x.x if connecting from a machine other than the production server.

---

## How the Repositories Work Together

### 1. **Backend (`tincan-backend`)**
- **Role**: Manages all application logic and interacts with the PostgreSQL database.
- **Docker Image**: Built using the `build_and_push.sh` script in the `tincan-backend` repository.
- **Usage in `tincan-deploy`**: Pulled as the `backend` service and connected to the `db` service.

### 2. **Frontend (`tincan-frontend`)**
- **Role**: Provides the user interface and communicates with the backend API.
- **Docker Image**: Built using the `build_and_push.sh` script in the `tincan-frontend` repository.
- **Usage in `tincan-deploy`**: Pulled as the `frontend` service and exposed through the `nginx` reverse proxy.

### 3. **Nginx (`tincan-nginx`)**
- **Role**: Routes requests to the frontend and backend services and handles CORS configuration.
- **Docker Image**: Built using the `build_and_push.sh` script in the `tincan-nginx` repository.
- **Usage in `tincan-deploy`**: Pulled as the `nginx` service and exposed on port `80`.

---

## Logs and Troubleshooting

- **Application Logs**:
  Logs are stored in the `./log` directory for both the backend and nginx services.

- **Database Logs**:
  PostgreSQL logs are stored within the container volume `pgdata`.

- **Common Commands**:
  - Restart services: `docker-compose restart`
  - View logs: `docker-compose logs -f`
  - Stop services: `docker-compose down`

---

## Links to Other Repositories
- [Tincan Backend](https://github.com/pdayboch/tincan-backend)
- [Tincan Frontend](https://github.com/pdayboch/tincan-frontend)
- [Tincan Nginx](https://github.com/pdayboch/tincan-nginx)

---

## Contributions
Feel free to contribute to the Tincan project by submitting issues or pull requests to the respective repositories.

---

## License
This project is licensed under the MIT License. See the LICENSE file for details.

