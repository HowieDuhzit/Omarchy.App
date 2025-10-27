# 🚀 Omarchy Directory Deployment Guide

## Coolify + Nixpacks Deployment

This application is optimized for deployment using **Coolify** with **Nixpacks** build system.

### Prerequisites

- Coolify instance
- GitHub repository connected to Coolify

### Deployment Steps

1. **Push to GitHub** (repository already exists)

2. **Create Service in Coolify**:
   - **Source**: Git Repository
   - **Repository**: `https://github.com/HowieDuhzit/OmarchyWebAppDirectory`
   - **Branch**: `main`
   - **Build Pack**: Nixpacks (automatically detected)

3. **Configure Environment Variables**:
   ```bash
   ADMIN_PASSWORD=<your_secure_password>
   SECRET_KEY_BASE=<generate_random_32_char_string>
   APP_HOST=yourdomain.com
   RAILS_ENV=production
   ```
   *Note: No DATABASE_URL needed - SQLite is used automatically*

4. **Deploy**:
   - Coolify will automatically detect Rails + SQLite + Node.js
   - Nixpacks will handle dependency installation and asset compilation
   - Application will be available on port 3000

### Files Created for Deployment

- **`.ruby-version`**: Specifies Ruby 3.2.9 for Nixpacks
- **`nixpacks.toml`**: Optimizes build process and commands
- **`.env.example`**: Template for environment variables

### Database

- Uses **SQLite** for simplicity and portability
- Database file automatically created in `/app/db/production.sqlite3`
- 135+ webapps are pre-seeded with categories
- No external database server required

### Features

- ✅ Responsive Tailwind CSS UI
- ✅ 135 categorized webapps
- ✅ Full CRUD functionality
- ✅ API endpoints (JSON)
- ✅ Admin authentication
- ✅ Search and filtering
- ✅ Mobile-friendly design

### Troubleshooting

If deployment fails:
1. Check that `.ruby-version` file exists
2. Ensure environment variables are set
3. Verify Nixpacks is selected as build pack
4. Check Coolify logs for specific errors

### Production URLs

- **Main App**: `https://yourdomain.com`
- **Health Check**: `https://yourdomain.com/health`
- **API**: `https://yourdomain.com/webapps.json`
