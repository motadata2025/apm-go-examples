package db

import (
	"context"
	"database/sql"
	"db-sql-multi/internal/config"
	"log/slog"
	"time"

	_ "github.com/go-sql-driver/mysql" // MySQL
	_ "github.com/lib/pq"              // PostgreSQL
)

type Pair struct {
	My *sql.DB
	Pg *sql.DB
}

func Open(cfg config.AppConfig, logger *slog.Logger) (Pair, error) {
	open := func(driver, dsn string, maxOpen, maxIdle int, life time.Duration) (*sql.DB, error) {
		db, err := sql.Open(driver, dsn)
		if err != nil {
			return nil, err
		}
		db.SetMaxOpenConns(maxOpen)
		db.SetMaxIdleConns(maxIdle)
		db.SetConnMaxLifetime(life)
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if err := db.PingContext(ctx); err != nil {
			return nil, err
		}
		return db, nil
	}
	my, err := open(cfg.MySQL.Driver, cfg.MySQL.DSN, cfg.MySQL.MaxOpen, cfg.MySQL.MaxIdle, cfg.MySQL.ConnMaxLifetime)
	if err != nil {
		return Pair{}, err
	}
	pg, err := open(cfg.PG.Driver, cfg.PG.DSN, cfg.PG.MaxOpen, cfg.PG.MaxIdle, cfg.PG.ConnMaxLifetime)
	if err != nil {
		my.Close()
		return Pair{}, err
	}
	logger.Info("databases connected")
	return Pair{My: my, Pg: pg}, nil
}
