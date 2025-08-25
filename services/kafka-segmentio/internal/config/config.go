package config

import "os"

type Conf struct {
	Brokers []string
	TopicA  string
	TopicB  string
	GroupID string
}

func Load() Conf {
	b := os.Getenv("KAFKA_BROKERS")
	if b == "" {
		b = "127.0.0.1:9092"
	}
	return Conf{
		Brokers: []string{b},
		TopicA:  env("TOPIC_A", "orders"),
		TopicB:  env("TOPIC_B", "payments"),
		GroupID: env("GROUP_ID", "demo-consumers"),
	}
}
func env(k, d string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return d
}
