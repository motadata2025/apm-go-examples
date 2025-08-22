package svc

import (
	"context"
	"time"

	"grpc-svc/grpc-svc/api/proto"
)

type Echo struct {
	proto.UnimplementedEchoServiceServer
}

func (e *Echo) Say(ctx context.Context, req *proto.SayRequest) (*proto.SayResponse, error) {
	return &proto.SayResponse{Msg: "echo: " + req.GetMsg()}, nil
}

func (e *Echo) StreamCount(req *proto.CountRequest, srv proto.EchoService_StreamCountServer) error {
	from, to := req.GetFrom(), req.GetTo()
	if to < from {
		from, to = to, from
	}
	for i := from; i <= to; i++ {
		if err := srv.Send(&proto.CountTick{Value: i}); err != nil {
			return err
		}
		time.Sleep(150 * time.Millisecond)
	}
	return nil
}
