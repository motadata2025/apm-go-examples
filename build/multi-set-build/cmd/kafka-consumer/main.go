package main

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"os"
	"os/signal"
	"syscall"

	"kafka-segmentio/internal/config"
	"kafka-segmentio/internal/kafkautil"
	"kafka-segmentio/internal/model"

	"github.com/segmentio/kafka-go"
)

func main() {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	cfg := config.Load()

	rA := kafkautil.NewReader(cfg.Brokers, cfg.GroupID, cfg.TopicA)
	rB := kafkautil.NewReader(cfg.Brokers, cfg.GroupID, cfg.TopicB)
	defer rA.Close()
	defer rB.Close()

	ctx, cancel := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer cancel()

	logger.Info("Kafka consumer started", "topics", []string{cfg.TopicA, cfg.TopicB})

	go consumeOrders(ctx, rA, logger)
	go consumePayments(ctx, rB, logger)
	<-ctx.Done()
	logger.Info("shutdown")
}

func consumeOrders(ctx context.Context, r *kafka.Reader, log *slog.Logger) {
	for {
		m, err := r.FetchMessage(ctx)
		if err != nil {
			if errors.Is(err, context.Canceled) {
				return
			}
			log.Error("fetch", "err", err)
			continue
		}
		var evt model.OrderCreated
		if err := json.Unmarshal(m.Value, &evt); err != nil {
			log.Error("json", "err", err)
			continue
		}
		log.Info("order", "key", string(m.Key), "amount", evt.Amount)
		_ = r.CommitMessages(ctx, m)
	}
}

func consumePayments(ctx context.Context, r *kafka.Reader, log *slog.Logger) {
	for {
		m, err := r.FetchMessage(ctx)
		if err != nil {
			if errors.Is(err, context.Canceled) {
				return
			}
			log.Error("fetch", "err", err)
			continue
		}
		var evt model.PaymentReceived
		if err := json.Unmarshal(m.Value, &evt); err != nil {
			log.Error("json", "err", err)
			continue
		}
		log.Info("payment", "key", string(m.Key), "order", evt.OrderID)
		_ = r.CommitMessages(ctx, m)
	}
}
