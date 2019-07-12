// Code generated by mockery v1.0.0. DO NOT EDIT.

package mocks

import mock "github.com/stretchr/testify/mock"
import models "github.com/edgexfoundry/go-mod-core-contracts/models"

// CommandLoader is an autogenerated mock type for the CommandLoader type
type CommandLoader struct {
	mock.Mock
}

// GetAllCommands provides a mock function with given fields:
func (_m *CommandLoader) GetAllCommands() ([]models.Command, error) {
	ret := _m.Called()

	var r0 []models.Command
	if rf, ok := ret.Get(0).(func() []models.Command); ok {
		r0 = rf()
	} else {
		if ret.Get(0) != nil {
			r0 = ret.Get(0).([]models.Command)
		}
	}

	var r1 error
	if rf, ok := ret.Get(1).(func() error); ok {
		r1 = rf()
	} else {
		r1 = ret.Error(1)
	}

	return r0, r1
}

// GetCommandsByDeviceId provides a mock function with given fields: did
func (_m *CommandLoader) GetCommandsByDeviceId(did string) ([]models.Command, error) {
	ret := _m.Called(did)

	var r0 []models.Command
	if rf, ok := ret.Get(0).(func(string) []models.Command); ok {
		r0 = rf(did)
	} else {
		if ret.Get(0) != nil {
			r0 = ret.Get(0).([]models.Command)
		}
	}

	var r1 error
	if rf, ok := ret.Get(1).(func(string) error); ok {
		r1 = rf(did)
	} else {
		r1 = ret.Error(1)
	}

	return r0, r1
}