export interface AuthUser {
  id: string;
  name: string;
  email: string;
  password: string;
}

export interface AuthSession {
  userId: string;
}
