package main

import (
	"log"
	"net"
	"os"

	"grpc-svc/grpc-svc/api/proto"
	"grpc-svc/internal/logx"
	"grpc-svc/internal/svc"

	"google.golang.org/grpc"
)

func main() {
	logger := logx.New()
	
	// Get gRPC server address from environment or use default
	grpcAddr := os.Getenv("GRPC_SERVER_ADDR")
	if grpcAddr == "" {
		grpcAddr = ":50051"
	}
	
	lis, err := net.Listen("tcp", grpcAddr)
	if err != nil {
		log.Fatal(err)
	}

	server := grpc.NewServer()
	proto.RegisterEchoServiceServer(server, &svc.Echo{})
	logger.Info("gRPC server listening", "addr", grpcAddr)
	if err := server.Serve(lis); err != nil {
		log.Fatal(err)
	}
}
