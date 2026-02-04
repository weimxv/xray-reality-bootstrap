# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2024-02-04

### 新增功能
- ✨ 全自动 Xray Reality 部署脚本
- 🌐 智能 IPv4/IPv6 双栈检测与策略选择
- ⚡  BBR 拥塞控制自动启用
- 💾 低内存 VPS 自动创建 Swap
- 🛡️ iptables + Fail2ban 安全防护
- 📊 SNI 域名自动测速优选
- 📱 `xinfo` 管理工具（支持二维码生成）
- 🔄 GeoIP / Geosite 数据自动下载

### 技术特性
- 模块化设计，职责分离
- 所有操作可追溯，避免黑盒
- 重试机制保证稳定性
- 倒计时交互避免长时间等待

### 文档
- 完整的 README 说明文档
- 故障排查指南
- 安全建议

---

## 计划功能

### [1.1.0] - 待定
- [ ] 支持 xhttp 协议（双节点模式）
- [ ] 支持自定义 GeoData 源
- [ ] 增加端口管理工具
- [ ] 增加网络策略切换工具

### [Future]
- [ ] 支持多配置文件切换
- [ ] 支持 WARP 分流
- [ ] 支持流量统计（轻量级）
