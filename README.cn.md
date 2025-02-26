# HappyNotes - 像发微博一样轻松记笔记

HappyNotes是一款支持所有平台的力图保持简单同时功能强大的笔记app。

## 为什么叫 HappyNotes？

取这个名字是受 HappyFeed 的启发，我曾是 HappyFeed 免费版的重度用户。我得说它蛮好用，如果你的目标只是写日记，哦，差点歪楼去推荐
HappyFeed，也还是欢迎你用 HappyNotes.
快乐笔记，记录你的开心生活。多么好的愿景啊，但日子并不总是阳光，所以我也有记录一些其他的心路历程。Stop！还是让我们多多记录生活中的开心一刻！

## 为什么不用其它现成的笔记软件？

首先是，这些App的免费版限制太多了！再一个理由是，我虽然是个程序员，可我的产品经理梦还在燃烧呢！我想要打造一款至少自己用起来很爽的app来<del>
“证明”一下自己</del>回馈社会。

## HappyNotes 有什么特别的？

### 1. 文本为王

HappyNotes允许你上传照片，但照片上传成功即成为 Markdown文本的一部分。也就是说，你备份了文本，也就"备份"
了你的照片。

### 2. 支持私密文本，但不支持私密照片

也就是说即使你的某篇笔记是私密的，但笔记里的照片却是公开的。这从源头上杜绝了私密照片泄漏的可能性！私密的照片请干脆不要上传。记住：云带来方便却降低了安全性。

- 右上角的铅笔默认用来写公开笔记
    - 设置中有一项可以 override 掉此默认设置，从而各个写笔记入口都默认写私密笔记
- 主导航的+号默认用来写私密笔记
- 图片Host在 HappyNotes 的图片服务器上，知道图片 URL 的任何人都可以访问到你的照片。重要的事情说三遍：*
  *请务必不要上传私密照片。请务必不要上传私密照片。请务必不要上传私密照片**。

### 3. 支持按天查看笔记/日记

- 想知道去年自己的生日是怎么过得？轻敲 My Notes
  标题，输入一个日期即可直达那一天的笔记。还想看这一天的前一天？HappyNotes允许你在任意一天的笔记页面翻阅
  前一天 和 后一天。这就像你的纸质笔记本，飜到某一天，接着往前翻就是前一天，接着向后翻就是后一天。
- 其实这里还有一个 Bonus! 输入一个日期，除了可以看到该日期的笔记，HappyNotes还允许你在这一天追加记录任意多篇笔记。
  在某一天的笔记列表右下角有一个 +
  按钮，点击那个按钮即可在该日期写一篇新笔记。日期将是该日，时间则是笔记的创建时间。举例来说，你是在1989年1月1日这一页追加一篇笔记，而提交笔记的时间是
  2025年1月1日 12:00，则这篇笔记的发表时间将是 1989年1月1日 12:00。我希望我说明了。

### 4. 支持按 Tag 查看笔记

- 在笔记的列表上，有列出每一篇笔记中的 Tag。点击任何一个Tag可查看标记有该Tag
  的所有笔记。可是当前页并没有我想查看的那个Tag？轻敲 My Notes 标题，输入那个tag的文本即可直达该 tag
  专属页面，是不是挺方便的?!
- 长按 My Notes 标题，你会看到一个 Tag 云，你可以点击该云中的任何一个 Tag 查看标记有该Tag 的所有笔记。

### 5. 支持上传或者粘贴图片

- 目前需要在笔记编辑界面启用 Markdown 支持才能上传图片。轻点一下编辑框下方的 Markdown 开关即可开启/关闭
  该功能。你也可以在 Settings -> Markdown 中开启/关闭 Markdown 支持。

### 6. 支持同步笔记到 Telegram 频道

你可以选择同步所有笔记，或者仅公开笔记，
或者仅私密笔记，或者仅打有指定Tag的笔记到某个Telegram频道。我并不建议你同步你的私密笔记到你的一个公开Telegram频道。不过你非要做，HappyNotes并不会拦着你。
我一般会建立一个私密的频道同步我所有的笔记，这个频道的作用是备份。说句不好听的，虽然每个人都怀着美好愿望，但谁知道HappyNotes的服务能撑几天？几个月？或者几年？

### 7. 支持同步指定笔记到 Mastodon

你可以选择同步所有笔记，或者仅公开笔记， 或者仅打有 Mastodon标签的笔记到某个
Mastodon实例。私有的笔记会以私嘟形式发布。长度超过500字符的笔记会以长图的形式的发布。

- 若你把某个公开笔记改成了私有或者反过来，原来同步过的嘟会被删除重发。因此 Mastodon
  的时间线有可能与你的笔记时间线不一致。
- 因为 Mastodon 并不支持Markdown，因此Markdown笔记中图片的前四张会同步发往 Mastodon
  实例的媒体服务器。某种程度上，该Mastodon实例起到了备份你笔记图片的作用。

### 8. 支持“Discover”他人的公开笔记 （该功能目前仅支持Web，也许之后会开放给原生App）

### 9. 其他技巧
- **修改笔记**: 双击一篇笔记即可修改。
- **添加Tag**: 在笔记中末尾输入 `#example_tag` 或者笔记中间输入标签并在标签之后留一个空白
- **笔记详情**: 点击笔记发表时间或者 `View more`
- **想看指定页**: 长按当前页号即可输入一个页码，从而直达该页
- **设置页**:
  - 调整一页展示多少篇笔记
  - 设定你所在的时区
  - 启用Markdown支持

## 加入快乐笔记社区

点击以下链接加入Telegram群组来寻求支持或者分享你的使用技巧:

[Happy Notes Support Group](https://t.me/happynotes_support)

## License

本项目采用 MIT 授权。点击 [LICENSE](./LICENSE) 查看授权文件全文。
