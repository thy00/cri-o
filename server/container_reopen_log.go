package server

import (
	"fmt"

	"golang.org/x/net/context"
	pb "k8s.io/cri-api/pkg/apis/runtime/v1alpha2"
)

// ReopenContainerLog reopens the containers log file
func (s *Server) ReopenContainerLog(ctx context.Context, req *pb.ReopenContainerLogRequest) (resp *pb.ReopenContainerLogResponse, err error) {
	containerID := req.ContainerId
	c := s.GetContainer(containerID)

	if c == nil {
		return nil, fmt.Errorf("could not find container %q", containerID)
	}

	if err := c.IsAlive(); err != nil {
		return nil, fmt.Errorf("container is not created or running")
	}

	err = s.ContainerServer.Runtime().ReopenContainerLog(c)
	if err == nil {
		resp = &pb.ReopenContainerLogResponse{}
	}

	return resp, err
}
