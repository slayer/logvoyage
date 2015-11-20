// Help to track per-second user statistics.
// Each second time will collect data and send it to
// redis channel.
package backend

import (
	"sync"
	"time"

	"../web_socket"
)

type perSecondStorage struct {
	sync.Mutex
	Logs map[string]int // Logs per second map[apiKey]logsPerSecond
}

var prs = perSecondStorage{Logs: make(map[string]int)}

func initTimers() {
	ticker := time.NewTicker(1 * time.Second)

	defer ticker.Stop()

	for range ticker.C {
		prs.Lock()

		var message web_socket.RedisMessage
		for apiKey, logsPerSecond := range prs.Logs {
			if logsPerSecond > 0 {
				message = web_socket.RedisMessage{ApiKey: apiKey, Data: map[string]interface{}{
					"type":  "logs_per_second",
					"count": logsPerSecond,
				}}

				message.Send(redisConn)
			}
		}

		prs.Logs = make(map[string]int)
		prs.Unlock()
	}
}

// Increases counter of number of logs send to elastic
func increaseCounter(apiKey string) {
	prs.Lock()
	defer prs.Unlock()
	if _, ok := prs.Logs[apiKey]; ok {
		prs.Logs[apiKey] += 1
	} else {
		prs.Logs[apiKey] = 1
	}
}
