package logx

import (
	"log/slog"
	"os"
)

func New() *slog.Logger { return slog.New(slog.NewTextHandler(os.Stdout, nil)) }
