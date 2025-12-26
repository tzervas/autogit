//! GitLab API client module

mod auth;
mod client;
mod projects;
mod runners;
mod tokens;
mod users;

pub use auth::{AuthMethod, Token};
pub use client::{GitLabClient, GitLabClientBuilder};
pub use projects::{
    CreateProjectRequest, MirrorConfig, Project, ProjectNamespace, Visibility,
};
pub use runners::{
    RegisterRunnerRequest, RegisterRunnerResponse, Runner, RunnerDetail, RunnerInfo,
    RunnerStatus, RunnerType, UpdateRunnerRequest,
};
pub use tokens::{CreateTokenRequest, PersonalAccessToken, TokenScope};
pub use users::{CreateUserRequest, User, UserRole};
