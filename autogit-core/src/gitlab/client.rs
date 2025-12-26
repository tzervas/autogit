//! GitLab API client implementation

use reqwest::{Client, StatusCode};
use std::time::Duration;
use tracing::{debug, instrument, warn};
use url::Url;

use super::auth::AuthMethod;
use super::projects::{CreateProjectRequest, MirrorConfig, Project};
use super::runners::{
    RegisterRunnerRequest, RegisterRunnerResponse, Runner, RunnerDetail, UpdateRunnerRequest,
};
use super::tokens::{CreateTokenRequest, PersonalAccessToken};
use super::users::{CreateUserRequest, User};
use crate::error::{Error, Result};

/// GitLab API client with connection pooling and retry logic
pub struct GitLabClient {
    http: Client,
    base_url: Url,
    auth: AuthMethod,
}

impl GitLabClient {
    /// Create a new client builder
    pub fn builder() -> GitLabClientBuilder {
        GitLabClientBuilder::default()
    }

    /// Get the base URL
    pub fn base_url(&self) -> &Url {
        &self.base_url
    }

    /// Make authenticated GET request
    #[instrument(skip(self), fields(url = %endpoint))]
    async fn get<T: serde::de::DeserializeOwned>(&self, endpoint: &str) -> Result<T> {
        let url = self.base_url.join(&format!("api/v4{endpoint}"))?;
        debug!("GET {}", url);

        let response = self
            .http
            .get(url)
            .header(self.auth.header_name(), self.auth.header_value())
            .send()
            .await?;

        self.handle_response(response).await
    }

    /// Make authenticated POST request with JSON body
    #[instrument(skip(self, body), fields(url = %endpoint))]
    async fn post<T, B>(&self, endpoint: &str, body: &B) -> Result<T>
    where
        T: serde::de::DeserializeOwned,
        B: serde::Serialize + ?Sized,
    {
        let url = self.base_url.join(&format!("api/v4{endpoint}"))?;
        debug!("POST {}", url);

        let response = self
            .http
            .post(url)
            .header(self.auth.header_name(), self.auth.header_value())
            .json(body)
            .send()
            .await?;

        self.handle_response(response).await
    }

    /// Make authenticated POST request without expecting a response body
    #[instrument(skip(self), fields(url = %endpoint))]
    async fn post_empty(&self, endpoint: &str) -> Result<()> {
        let url = self.base_url.join(&format!("api/v4{endpoint}"))?;
        debug!("POST {} (empty)", url);

        let response = self
            .http
            .post(url)
            .header(self.auth.header_name(), self.auth.header_value())
            .send()
            .await?;

        let status = response.status();
        if status.is_success() || status == StatusCode::NO_CONTENT {
            Ok(())
        } else {
            let body = response.text().await.unwrap_or_default();
            Err(Error::gitlab_api(status.as_u16(), body))
        }
    }

    /// Make authenticated PUT request with JSON body
    #[instrument(skip(self, body), fields(url = %endpoint))]
    async fn put<T, B>(&self, endpoint: &str, body: &B) -> Result<T>
    where
        T: serde::de::DeserializeOwned,
        B: serde::Serialize + ?Sized,
    {
        let url = self.base_url.join(&format!("api/v4{endpoint}"))?;
        debug!("PUT {}", url);

        let response = self
            .http
            .put(url)
            .header(self.auth.header_name(), self.auth.header_value())
            .json(body)
            .send()
            .await?;

        self.handle_response(response).await
    }

    /// Make authenticated DELETE request
    #[instrument(skip(self), fields(url = %endpoint))]
    async fn delete(&self, endpoint: &str) -> Result<()> {
        let url = self.base_url.join(&format!("api/v4{endpoint}"))?;
        debug!("DELETE {}", url);

        let response = self
            .http
            .delete(url)
            .header(self.auth.header_name(), self.auth.header_value())
            .send()
            .await?;

        let status = response.status();
        if status.is_success() || status == StatusCode::NO_CONTENT {
            Ok(())
        } else {
            let body = response.text().await.unwrap_or_default();
            Err(Error::gitlab_api(status.as_u16(), body))
        }
    }

    /// Handle API response, converting errors appropriately
    async fn handle_response<T: serde::de::DeserializeOwned>(
        &self,
        response: reqwest::Response,
    ) -> Result<T> {
        let status = response.status();

        if status.is_success() {
            Ok(response.json().await?)
        } else {
            let body = response.text().await.unwrap_or_default();

            // Parse GitLab error format
            let message = if let Ok(json) = serde_json::from_str::<serde_json::Value>(&body) {
                json.get("message")
                    .or_else(|| json.get("error"))
                    .and_then(|v| v.as_str())
                    .unwrap_or(&body)
                    .to_string()
            } else {
                body
            };

            match status {
                StatusCode::UNAUTHORIZED => Err(Error::Authentication(message)),
                StatusCode::NOT_FOUND => Err(Error::UserNotFound(message)),
                StatusCode::CONFLICT => Err(Error::UserExists(message)),
                _ => Err(Error::gitlab_api(status.as_u16(), message)),
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // User Operations
    // ─────────────────────────────────────────────────────────────────────────

    /// Get current authenticated user
    #[instrument(skip(self))]
    pub async fn current_user(&self) -> Result<User> {
        self.get("/user").await
    }

    /// List all users (admin only)
    #[instrument(skip(self))]
    pub async fn list_users(&self) -> Result<Vec<User>> {
        self.get("/users").await
    }

    /// Get user by username
    #[instrument(skip(self))]
    pub async fn get_user_by_username(&self, username: &str) -> Result<Option<User>> {
        let users: Vec<User> = self.get(&format!("/users?username={username}")).await?;
        Ok(users.into_iter().next())
    }

    /// Get user by ID
    #[instrument(skip(self))]
    pub async fn get_user(&self, user_id: u64) -> Result<User> {
        self.get(&format!("/users/{user_id}")).await
    }

    /// Check if user exists
    #[instrument(skip(self))]
    pub async fn user_exists(&self, username: &str) -> Result<bool> {
        Ok(self.get_user_by_username(username).await?.is_some())
    }

    /// Create a new user (admin only)
    #[instrument(skip(self, request), fields(username = %request.username))]
    pub async fn create_user(&self, request: &CreateUserRequest) -> Result<User> {
        self.post("/users", request).await
    }

    /// Delete a user (admin only)
    #[instrument(skip(self))]
    pub async fn delete_user(&self, user_id: u64) -> Result<()> {
        self.delete(&format!("/users/{user_id}")).await
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Token Operations
    // ─────────────────────────────────────────────────────────────────────────

    /// Create personal access token for user (admin only)
    #[instrument(skip(self, request), fields(user_id = user_id, name = %request.name))]
    pub async fn create_user_token(
        &self,
        user_id: u64,
        request: &CreateTokenRequest,
    ) -> Result<PersonalAccessToken> {
        self.post(&format!("/users/{user_id}/personal_access_tokens"), request)
            .await
    }

    /// List personal access tokens for current user
    #[instrument(skip(self))]
    pub async fn list_my_tokens(&self) -> Result<Vec<PersonalAccessToken>> {
        self.get("/personal_access_tokens").await
    }

    /// Revoke a personal access token
    #[instrument(skip(self))]
    pub async fn revoke_token(&self, token_id: u64) -> Result<()> {
        self.delete(&format!("/personal_access_tokens/{token_id}"))
            .await
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Project Operations
    // ─────────────────────────────────────────────────────────────────────────

    /// List all projects (paginated, returns first page)
    #[instrument(skip(self))]
    pub async fn list_projects(&self) -> Result<Vec<Project>> {
        self.get("/projects?per_page=100").await
    }

    /// Get project by path (e.g., "group/project")
    #[instrument(skip(self))]
    pub async fn get_project(&self, path: &str) -> Result<Option<Project>> {
        let encoded = urlencoding::encode(path);
        match self.get::<Project>(&format!("/projects/{encoded}")).await {
            Ok(project) => Ok(Some(project)),
            Err(Error::UserNotFound(_)) => Ok(None), // 404 → not found
            Err(e) => Err(e),
        }
    }

    /// Get project by ID
    #[instrument(skip(self))]
    pub async fn get_project_by_id(&self, project_id: u64) -> Result<Project> {
        self.get(&format!("/projects/{project_id}")).await
    }

    /// Create a new project
    #[instrument(skip(self, request), fields(name = %request.name))]
    pub async fn create_project(&self, request: &CreateProjectRequest) -> Result<Project> {
        self.post("/projects", request).await
    }

    /// Delete a project
    #[instrument(skip(self))]
    pub async fn delete_project(&self, project_id: u64) -> Result<()> {
        self.delete(&format!("/projects/{project_id}")).await
    }

    /// Configure pull mirror for a project (requires Premium/Ultimate or self-managed)
    #[instrument(skip(self, config), fields(project_id = project_id))]
    pub async fn configure_pull_mirror(
        &self,
        project_id: u64,
        config: &MirrorConfig,
    ) -> Result<Project> {
        self.put(
            &format!("/projects/{project_id}"),
            &serde_json::json!({
                "import_url": config.url,
                "mirror": config.enabled,
                "only_mirror_protected_branches": config.only_protected_branches,
            }),
        )
        .await
    }

    /// Trigger mirror update for a project
    #[instrument(skip(self))]
    pub async fn trigger_mirror_pull(&self, project_id: u64) -> Result<()> {
        self.post_empty(&format!("/projects/{project_id}/mirror/pull"))
            .await
    }

    /// List projects configured as pull mirrors
    #[instrument(skip(self))]
    pub async fn list_mirror_projects(&self) -> Result<Vec<Project>> {
        // Filter locally since GitLab doesn't have a direct mirror filter
        let projects = self.list_projects().await?;
        Ok(projects.into_iter().filter(|p| p.mirror).collect())
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Runner Operations
    // ─────────────────────────────────────────────────────────────────────────

    /// List all runners accessible to current user
    #[instrument(skip(self))]
    pub async fn list_runners(&self) -> Result<Vec<Runner>> {
        self.get("/runners/all?per_page=100").await
    }

    /// List runners for a specific project
    #[instrument(skip(self))]
    pub async fn list_project_runners(&self, project_id: u64) -> Result<Vec<Runner>> {
        self.get(&format!("/projects/{project_id}/runners")).await
    }

    /// Get runner details
    #[instrument(skip(self))]
    pub async fn get_runner(&self, runner_id: u64) -> Result<RunnerDetail> {
        self.get(&format!("/runners/{runner_id}")).await
    }

    /// Register a new runner (uses registration token)
    ///
    /// Note: This uses a different auth mechanism (registration token in body)
    #[instrument(skip(self, request))]
    pub async fn register_runner(&self, request: &RegisterRunnerRequest) -> Result<RegisterRunnerResponse> {
        // Runner registration endpoint doesn't require auth header
        let url = self.base_url.join("api/v4/runners")?;
        debug!("POST {} (runner registration)", url);

        let response = self.http.post(url).json(request).send().await?;
        self.handle_response(response).await
    }

    /// Update runner configuration
    #[instrument(skip(self, request), fields(runner_id = runner_id))]
    pub async fn update_runner(
        &self,
        runner_id: u64,
        request: &UpdateRunnerRequest,
    ) -> Result<RunnerDetail> {
        self.put(&format!("/runners/{runner_id}"), request).await
    }

    /// Pause a runner
    #[instrument(skip(self))]
    pub async fn pause_runner(&self, runner_id: u64) -> Result<RunnerDetail> {
        self.update_runner(runner_id, &UpdateRunnerRequest::pause()).await
    }

    /// Unpause a runner
    #[instrument(skip(self))]
    pub async fn unpause_runner(&self, runner_id: u64) -> Result<RunnerDetail> {
        self.update_runner(runner_id, &UpdateRunnerRequest::unpause()).await
    }

    /// Delete/unregister a runner
    #[instrument(skip(self))]
    pub async fn delete_runner(&self, runner_id: u64) -> Result<()> {
        self.delete(&format!("/runners/{runner_id}")).await
    }

    /// Get instance-level runner registration token (admin only)
    #[instrument(skip(self))]
    pub async fn get_instance_runner_token(&self) -> Result<String> {
        #[derive(serde::Deserialize)]
        struct TokenResponse {
            token: String,
        }
        let resp: TokenResponse = self.post("/runners/reset_registration_token", &()).await?;
        Ok(resp.token)
    }
}

impl std::fmt::Debug for GitLabClient {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("GitLabClient")
            .field("base_url", &self.base_url)
            .field("auth", &self.auth)
            .finish()
    }
}

/// Builder for GitLabClient with sensible defaults
#[derive(Default)]
pub struct GitLabClientBuilder {
    base_url: Option<Url>,
    auth: Option<AuthMethod>,
    timeout: Option<Duration>,
    allow_insecure: bool,
}

impl GitLabClientBuilder {
    /// Set the GitLab instance URL
    pub fn base_url(mut self, url: impl AsRef<str>) -> Result<Self> {
        self.base_url = Some(Url::parse(url.as_ref())?);
        Ok(self)
    }

    /// Set authentication method
    pub fn auth(mut self, auth: AuthMethod) -> Self {
        self.auth = Some(auth);
        self
    }

    /// Set request timeout (default: 30s)
    pub fn timeout(mut self, timeout: Duration) -> Self {
        self.timeout = Some(timeout);
        self
    }

    /// Allow insecure connections (localhost only!)
    ///
    /// # Security
    /// Only use this for localhost development. Production should always use TLS.
    pub fn allow_insecure_localhost(mut self) -> Self {
        self.allow_insecure = true;
        self
    }

    /// Build the client
    pub fn build(self) -> Result<GitLabClient> {
        let base_url = self.base_url.ok_or(Error::Config("base_url required".into()))?;
        let auth = self.auth.ok_or(Error::Config("auth required".into()))?;

        // Security check: only allow HTTP for localhost
        if base_url.scheme() == "http" {
            let host = base_url.host_str().unwrap_or("");
            let is_localhost = host == "localhost" || host == "127.0.0.1" || host.starts_with("192.168.");

            if !is_localhost && !self.allow_insecure {
                warn!("Refusing HTTP connection to non-local host: {}", host);
                return Err(Error::Config(format!(
                    "HTTP not allowed for non-localhost: {}. Use HTTPS or allow_insecure_localhost()",
                    host
                )));
            }
        }

        let timeout = self.timeout.unwrap_or(Duration::from_secs(30));

        let http = Client::builder()
            .timeout(timeout)
            .pool_max_idle_per_host(4)
            .build()?;

        Ok(GitLabClient {
            http,
            base_url,
            auth,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::gitlab::Token;

    #[test]
    fn builder_requires_url() {
        let result = GitLabClient::builder()
            .auth(AuthMethod::PrivateToken(Token::new("test")))
            .build();

        assert!(matches!(result, Err(Error::Config(_))));
    }

    #[test]
    fn builder_requires_auth() {
        let result = GitLabClient::builder()
            .base_url("http://localhost:8080")
            .unwrap()
            .build();

        assert!(matches!(result, Err(Error::Config(_))));
    }

    #[test]
    fn rejects_http_for_remote() {
        let result = GitLabClient::builder()
            .base_url("http://gitlab.example.com")
            .unwrap()
            .auth(AuthMethod::PrivateToken(Token::new("test")))
            .build();

        assert!(matches!(result, Err(Error::Config(_))));
    }

    #[test]
    fn allows_http_for_localhost() {
        let result = GitLabClient::builder()
            .base_url("http://localhost:8080")
            .unwrap()
            .auth(AuthMethod::PrivateToken(Token::new("test")))
            .build();

        assert!(result.is_ok());
    }
}
