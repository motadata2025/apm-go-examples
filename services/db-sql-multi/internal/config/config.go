package config

import (
	"fmt"
	"os"
	"strconv"
	"time"
)

type DBConfig struct {
	Driver           string // "mysql" or "postgres"
	DSN              string // full DSN string
	MaxOpen, MaxIdle int
	ConnMaxLifetime  time.Duration
}

type AppConfig struct {
	MySQL DBConfig
	PG    DBConfig
}

func mustEnv(key, def string) string {
	v := os.Getenv(key)
	if v == "" {
		if def != "" {
			return def
		}
		panic(fmt.Sprintf("missing env %s", key))
	}
	return v
}

func mustInt(key string, def int) int {
	v := os.Getenv(key)
	if v == "" {
		return def
	}
	n, err := strconv.Atoi(v)
	if err != nil {
		panic(err)
	}
	return n
}

func Load() AppConfig {
	return AppConfig{
		MySQL: DBConfig{
			Driver:          "mysql",
			DSN:             mustEnv("MYSQL_DSN", "root:rootpass@tcp(0.0.0.0:3306)/testdb?parseTime=true"),
			MaxOpen:         mustInt("MYSQL_MAX_OPEN", 10),
			MaxIdle:         mustInt("MYSQL_MAX_IDLE", 5),
			ConnMaxLifetime: time.Minute * 30,
		},
		PG: DBConfig{
			Driver:          "postgres",
			DSN:             mustEnv("PG_DSN", "postgres://testuser:Test%401234@0.0.0.0:5432/testdb?sslmode=disable"), //password is Test@1234
			MaxOpen:         mustInt("PG_MAX_OPEN", 10),
			MaxIdle:         mustInt("PG_MAX_IDLE", 5),
			ConnMaxLifetime: time.Minute * 30,
		},
	}
}
