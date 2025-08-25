// internal/repo/user_pg.go
package repo

import (
	"context"
	"database/sql"
	"errors"

	"db-sql-multi/internal/model"
)

type PGUserRepo struct{ DB *sql.DB }

func (r PGUserRepo) Migrate(ctx context.Context) error {
	_, err := r.DB.ExecContext(ctx, `
CREATE TABLE IF NOT EXISTS users (
  id BIGSERIAL PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  name  TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
)`)
	return err
}

func (r PGUserRepo) Create(ctx context.Context, u *model.User) error {
	err := r.DB.QueryRowContext(ctx,
		`INSERT INTO users (email,name) VALUES ($1,$2) RETURNING id, created_at`,
		u.Email, u.Name).Scan(&u.ID, &u.CreatedAt)
	return err
}

func (r PGUserRepo) GetByEmail(ctx context.Context, email string) (model.User, error) {
	var u model.User
	err := r.DB.QueryRowContext(ctx, `SELECT id,email,name,created_at FROM users WHERE email=$1`, email).
		Scan(&u.ID, &u.Email, &u.Name, &u.CreatedAt)
	if errors.Is(err, sql.ErrNoRows) {
		return model.User{}, err
	}
	return u, err
}

func (r PGUserRepo) UpdateName(ctx context.Context, id int64, name string) error {
	_, err := r.DB.ExecContext(ctx, `UPDATE users SET name=$1 WHERE id=$2`, name, id)
	return err
}

func (r PGUserRepo) Delete(ctx context.Context, id int64) error {
	_, err := r.DB.ExecContext(ctx, `DELETE FROM users WHERE id=$1`, id)
	return err
}

func (r PGUserRepo) TxSwapSuffix(ctx context.Context, aID, bID int64) error {
	tx, err := r.DB.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return err
	}
	defer tx.Rollback()
	if _, err = tx.ExecContext(ctx, `UPDATE users SET name=name||'_A' WHERE id=$1`, aID); err != nil {
		return err
	}
	if _, err = tx.ExecContext(ctx, `UPDATE users SET name=name||'_B' WHERE id=$1`, bID); err != nil {
		return err
	}
	return tx.Commit()
}
