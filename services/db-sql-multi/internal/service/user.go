package service

import (
	"context"
	"fmt"
	"log/slog"
	"strings"
	"time"

	"db-sql-multi/internal/model"
	"db-sql-multi/internal/repo"
)

type DualService struct {
	My  repo.MySQLUserRepo
	Pg  repo.PGUserRepo
	Log *slog.Logger
}

func (s DualService) Bootstrap(ctx context.Context) error {
	if err := s.My.Migrate(ctx); err != nil {
		return err
	}
	if err := s.Pg.Migrate(ctx); err != nil {
		return err
	}
	return nil
}

func randomEmail(name string) string {
	return fmt.Sprintf("%s_%d@example.com", strings.ToLower(name), time.Now().UnixNano())
}

func (s DualService) Demo(ctx context.Context) error {
	u1 := &model.User{Email: randomEmail("Alice"), Name: "Alice"}
	u2 := &model.User{Email: randomEmail("Bob"), Name: "Bob"}
	if err := s.My.Create(ctx, u1); err != nil {
		return err
	}
	if err := s.Pg.Create(ctx, u2); err != nil {
		return err
	}

	// Read
	_, _ = s.My.GetByEmail(ctx, u1.Email)
	_, _ = s.Pg.GetByEmail(ctx, u2.Email)

	// Update + Transactions
	if err := s.My.UpdateName(ctx, u1.ID, "AliceUpdated"); err != nil {
		return err
	}
	if err := s.Pg.UpdateName(ctx, u2.ID, "BobUpdated"); err != nil {
		return err
	}

	// Add another to show tx across rows
	u3 := &model.User{Email: randomEmail("Carol"), Name: "Carol"}
	_ = s.My.Create(ctx, u3)
	_ = s.My.TxTransfer(ctx, u1.ID, u3.ID)

	u4 := &model.User{Email: randomEmail("Dave"), Name: "Dave"}
	_ = s.Pg.Create(ctx, u4)
	_ = s.Pg.TxSwapSuffix(ctx, u2.ID, u4.ID)

	time.Sleep(100 * time.Millisecond) // give pool a bit of churn
	return nil
}
