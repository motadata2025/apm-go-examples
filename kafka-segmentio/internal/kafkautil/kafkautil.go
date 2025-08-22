package kafkautil

import (
	"context"
	"encoding/json"
	"log/slog"
	"time"

	"github.com/segmentio/kafka-go"
)

func NewWriter(brokers []string, topic string) *kafka.Writer {
	return &kafka.Writer{
		Addr:         kafka.TCP(brokers...),
		Topic:        topic,
		Balancer:     &kafka.LeastBytes{},
		RequiredAcks: kafka.RequireAll,
		Async:        false,
		BatchTimeout: time.Millisecond * 10,
	}
}

func NewReader(brokers []string, group, topic string) *kafka.Reader {
	return kafka.NewReader(kafka.ReaderConfig{
		Brokers:  brokers,
		GroupID:  group,
		Topic:    topic,
		MaxBytes: 10e6,
	})
}

func ProduceJSON(ctx context.Context, w *kafka.Writer, logger *slog.Logger, key string, v any) error {
	b, err := json.Marshal(v)
	if err != nil {
		return err
	}
	msg := kafka.Message{
		Key:     []byte(key),
		Value:   b,
		Time:    time.Now(),
		Headers: []kafka.Header{{Key: "content-type", Value: []byte("application/json")}},
	}
	if err := w.WriteMessages(ctx, msg); err != nil {
		return err
	}
	logger.Info("produced", "topic", w.Topic, "key", key)
	return nil
}
