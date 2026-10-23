import 'package:flutter/material.dart';

import '../../../core/updates/update_checker.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text('设置', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 18),
      const Card.outlined(
        child: ListTile(
          leading: Icon(Icons.system_update_outlined),
          title: Text('版本更新'),
          subtitle: Text('当前版本 0.1.0 · 可在官网查看经过校验的发布信息。'),
        ),
      ),
      const SizedBox(height: 12),
      const Card.outlined(
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('本地工具无需登录'),
              subtitle: Text('官方公式识别开放后才需要账号。'),
            ),
            Divider(height: 1),
            ListTile(
              leading: Icon(Icons.cloud_outlined),
              title: Text('识别服务'),
              subtitle: Text('后续可选择官方服务或配置自建接口。'),
            ),
            Divider(height: 1),
            ListTile(
              leading: Icon(Icons.privacy_tip_outlined),
              title: Text('隐私'),
              subtitle: Text('本地处理默认不上传文件。'),
            ),
          ],
        ),
      ),
    ],
  );
}
