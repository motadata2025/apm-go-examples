package main

import (
	"log"
	"net"

	"grpc-svc/grpc-svc/api/proto"
	"grpc-svc/internal/logx"
	"grpc-svc/internal/svc"

	"google.golang.org/grpc"
)

func main() {
	logger := logx.New()
	lis, err := net.Listen("tcp", ":50051")
	if err != nil {
		log.Fatal(err)
	}

	server := grpc.NewServer()
	proto.RegisterEchoServiceServer(server, &svc.Echo{})
	logger.Info("gRPC server listening", "addr", ":50051")
	if err := server.Serve(lis); err != nil {
		log.Fatal(err)
	}
}
