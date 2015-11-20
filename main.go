package main

import (
	"os"
	"runtime"

	"./commands"
	"github.com/codegangsta/cli"
)

func main() {
	runtime.GOMAXPROCS(runtime.NumCPU())
	app := cli.NewApp()
	app.Name = "LogVoyage"
	app.Commands = []cli.Command{
		commands.StartBackendServer,
		commands.StartWebServer,
		commands.StartAll,
		commands.CreateUsersIndex,
		commands.DeleteIndex,
		commands.CreateIndex,
	}
	app.Run(os.Args)
}
