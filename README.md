# echo-client
===============

## 介绍

### echo-client 使用说明


- 启动方式newclient:start(UserName,PassWord).   
#### 注意：
    第一次登录也需要设置登录密码，系统会保存该用户的账号密码
    用户登录的账号必须是全服务器唯一，否则登录失败

- 功能一 世界频道聊天
```erlang
例如 info> test 
其作用是直接在世界频道群发数据，在线的全部用户均可以看到
```
- 功能二 修改密码
```erlang
info> modify:newpasswd 
其作用是修改用户的密码为newpasswd
```
- 功能三 进入群聊讨论组，讨论组有两个分别是001/002
```erlang
info> entergroup:001
```
- 功能四 离开群聊讨论组，讨论组有两个分别是001/002
```erlang
info> leavegroup:001
```
- 功能五 讨论组聊天(如在001讨论组中发送msg数据
```erlang
info> groupto:001:msg
```
- 功能六 私聊（与test私聊）
```erlang
info> sendto:test:msg
```
- 功能七 获取世界频道的聊天记录
```erlang
info> get_world_chat_record:
```

#### 底层包含功能：
- 心跳包发送
