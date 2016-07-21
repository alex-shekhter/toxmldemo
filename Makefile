all:
	nex toxmldemo.nex
	go tool yacc -o=toxmldemo.yacc.go toxmldemo.y
	go fmt
	go build
clean:
	-rm *.output *.yacc.go *.nn.go
