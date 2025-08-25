// internal/repo/user_mysql.go
package repo

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"db-sql-multi/internal/model"
)

type MySQLUserRepo struct{ DB *sql.DB }

func (r MySQLUserRepo) Migrate(ctx context.Context) error {
	_, err := r.DB.ExecContext(ctx, `
CREATE TABLE IF NOT EXISTS users (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  name  VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
)`)
	return err
}

func (r MySQLUserRepo) Create(ctx context.Context, u *model.User) error {
	res, err := r.DB.ExecContext(ctx, `INSERT INTO users (email,name) VALUES (?,?)`, u.Email, u.Name)
	if err != nil {
		return err
	}
	id, err := res.LastInsertId()
	if err != nil {
		return err
	}
	u.ID = id
	u.CreatedAt = time.Now().UTC()
	return nil
}

func (r MySQLUserRepo) GetByEmail(ctx context.Context, email string) (model.User, error) {
	var u model.User
	err := r.DB.QueryRowContext(ctx, `SELECT id,email,name,created_at FROM users WHERE email=?`, email).
		Scan(&u.ID, &u.Email, &u.Name, &u.CreatedAt)
	if errors.Is(err, sql.ErrNoRows) {
		return model.User{}, err
	}
	return u, err
}

func (r MySQLUserRepo) UpdateName(ctx context.Context, id int64, name string) error {
	_, err := r.DB.ExecContext(ctx, `UPDATE users SET name=? WHERE id=?`, name, id)
	return err
}

func (r MySQLUserRepo) Delete(ctx context.Context, id int64) error {
	_, err := r.DB.ExecContext(ctx, `DELETE FROM users WHERE id=?`, id)
	return err
}

func (r MySQLUserRepo) TxTransfer(ctx context.Context, fromID, toID int64) error {
	// Simulate a transactional operation touching two rows (no money, just demo)
	tx, err := r.DB.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return err
	}
	defer tx.Rollback()
	if _, err = tx.ExecContext(ctx, `UPDATE users SET name=CONCAT(name,'_from') WHERE id=?`, fromID); err != nil {
		return err
	}
	if _, err = tx.ExecContext(ctx, `UPDATE users SET name=CONCAT(name,'_to') WHERE id=?`, toID); err != nil {
		return err
	}
	return tx.Commit()
}
