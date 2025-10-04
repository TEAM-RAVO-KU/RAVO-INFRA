[root@kubernetes-host ~]# curl 172.20.112.101:30888/status
{"service_target": "mysql-active", "watcher_state": "active"}

[root@kubernetes-host ~]# curl 172.20.112.101:30888/recover
{"message": "Recovery command issued."}

---
[root@master ravo]# k logs mysql-failover-watcher-747577465f-62zrt
Defaulted container "kubectl-watcher" out of: kubectl-watcher, api-server, conntrack-watcher, kubectl-downloader (init)
2025-10-04 05:27:48 [Watcher] Starting failover watcher.
2025-10-04 05:27:48 [Watcher] State: active, Service selector: mysql-active, ActiveReady: 1
2025-10-04 05:29:03 [Recovery] EVENT: Received recovery command.
2025-10-04 05:29:03 [Recovery] INFO: Already in active state. No action needed.

---
PS C:\Users\lenovo> curl http://xxx.xxx.xxx.xxx:8888/status                                                                                                                                                                                                                                                                                     StatusCode        : 200
StatusDescription : OK
Content           : {"service_target": "mysql-active", "watcher_state": "active"}
RawContent        : HTTP/1.1 200 OK
                    Transfer-Encoding: chunked
                    Connection: keep-alive
                    Content-Type: application/json
                    Date: Sat, 04 Oct 2025 05:31:38 GMT
                    Server: nginx/1.20.1

                    {"service_target": "mysql-active", "wa...
Forms             : {}
Headers           : {[Transfer-Encoding, chunked], [Connection, keep-alive], [Content-Type, application/json],
                    [Date, Sat, 04 Oct 2025 05:31:38 GMT]...}
Images            : {}
InputFields       : {}
Links             : {}
ParsedHtml        : System.__ComObject
RawContentLength  : 61


PS C:\Users\lenovo> curl http://xxx.xxx.xxx.xxx:8888/recover
StatusCode        : 200
StatusDescription : OK
Content           : {"message": "Recovery command issued."}
RawContent        : HTTP/1.1 200 OK
                    Transfer-Encoding: chunked
                    Connection: keep-alive
                    Content-Type: application/json
                    Date: Sat, 04 Oct 2025 05:31:54 GMT
                    Server: nginx/1.20.1

                    {"message": "Recovery command issued."...
Forms             : {}
Headers           : {[Transfer-Encoding, chunked], [Connection, keep-alive], [Content-Type, application/json],
                    [Date, Sat, 04 Oct 2025 05:31:54 GMT]...}
Images            : {}
InputFields       : {}
Links             : {}
ParsedHtml        : System.__ComObject
RawContentLength  : 39