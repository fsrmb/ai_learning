/**
 * Markdown → HTML 转换工具
 *
 * 用于 Dify AI 回复的富文本渲染。
 * ArkUI 的 RichText 组件支持 HTML，本工具将常见 Markdown 语法转为内联样式的 HTML。
 *
 * 支持的语法：
 *   - 代码块：```语言\n代码\n```
 *   - 行内代码：`代码`
 *   - 加粗：**文字**
 *   - 斜体：*文字*
 *   - 标题：# / ## / ###
 *   - 无序列表：- 文字
 *   - 有序列表：1. 文字
 *   - 换行：\n
 *
 * 使用方式：
 *   import { MarkdownUtil } from '../common/MarkdownUtil'
 *   RichText(MarkdownUtil.toHtml(aiReply))
 */
export class MarkdownUtil {
  static toHtml(markdown: string): string {
    let html = markdown

    // ① 代码块：```language\n代码\n``` → <pre><code>代码</code></pre>
    //    必须最先处理，避免代码块内部的内容被其他规则误匹配
    html = html.replace(
      /```(\w*)\n([\s\S]*?)```/g,
      (_match: string, _lang: string, code: string): string => {
        const escaped = MarkdownUtil.escapeHtml(code)
        return '<pre style="background:#f5f5f5;padding:12px;border-radius:8px;' +
          'overflow-x:auto;font-size:13px;line-height:1.5;">' +
          `<code>${escaped}</code></pre>`
      }
    )

    // ② 行内代码：`代码` → <code>代码</code>
    html = html.replace(
      /`([^`]+)`/g,
      '<code style="background:#f0f0f0;padding:2px 6px;border-radius:4px;font-size:13px;">$1</code>'
    )

    // ③ 加粗：**文字** → <b>文字</b>
    html = html.replace(/\*\*(.+?)\*\*/g, '<b>$1</b>')

    // ④ 斜体：*文字* → <i>文字</i>
    //    排除列表项（- * xxx）的情况，只匹配行内的 *xxx*
    html = html.replace(/(?<!\n\s*[-*]\s)\*(?!\s)(.+?)(?<!\s)\*/g, '<i>$1</i>')

    // ⑤ 标题：### / ## / # → <h4> / <h3> / <h3>
    //    用 h3/h4 避免在聊天气泡里太大
    html = html.replace(/^### (.+)$/gm, '<h4 style="margin:8px 0 4px 0;font-size:15px;">$1</h4>')
    html = html.replace(/^## (.+)$/gm, '<h3 style="margin:10px 0 6px 0;font-size:16px;">$1</h3>')
    html = html.replace(/^# (.+)$/gm, '<h3 style="margin:10px 0 6px 0;font-size:16px;">$1</h3>')

    // ⑥ 无序列表：- 文字 → <li>文字</li>
    html = html.replace(/^- (.+)$/gm, '<li style="margin-left:16px;margin-bottom:2px;">$1</li>')

    // ⑦ 有序列表：1. 文字 → <li>文字</li>
    html = html.replace(/^\d+\. (.+)$/gm, '<li style="margin-left:16px;margin-bottom:2px;">$1</li>')

    // ⑧ 换行：\n → <br>
    //    必须最后处理，避免干扰上面的多行正则
    html = html.replace(/\n/g, '<br>')

    // ⑨ 包裹基础样式（字体大小调整为 16px，与用户消息一致）
    return '<div style="font-size:16px;line-height:1.6;color:#333;word-break:break-all;">' +
      html + '</div>'
  }
  static toHtmlWithCustomStyle(markdown: string): string {
    // 先用原有方法转换为 HTML
    const html = MarkdownUtil.toHtml(markdown);

    // 包裹自定义样式：字体大小 16px，适合移动端
    return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body {
          font-size: 16px;        /* 调整字体大小，与用户消息一致 */
          line-height: 1.6;       /* 行高 */
          color: #333;
          margin: 0;
          padding: 4px 0;
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
        }
        code {
          font-size: 16px;
          background-color: #f0f0f0;
          padding: 2px 6px;
          border-radius: 4px;
        }
        pre {
          background-color: #f5f5f5;
          padding: 12px;
          border-radius: 8px;
          overflow-x: auto;
          font-size: 15px;
        }
        blockquote {
          border-left: 4px solid #409EFF;
          margin: 8px 0;
          padding-left: 12px;
          color: #666;
        }
        a {
          color: #409EFF;
          text-decoration: none;
        }
        img {
          max-width: 100%;
          border-radius: 8px;
        }
        ul, ol {
          padding-left: 20px;
        }
        h1, h2, h3 {
          margin: 8px 0;
        }
      </style>
    </head>
    <body>
      ${html}
    </body>
    </html>
  `;
  }
  /**
   * HTML 特殊字符转义
   * 防止代码块中的 < > & 被浏览器解析为 HTML 标签
   */
  private static escapeHtml(text: string): string {
    let result = text
    result = result.replace(/&/g, '&amp;')
    result = result.replace(/</g, '&lt;')
    result = result.replace(/>/g, '&gt;')
    result = result.replace(/"/g, '&quot;')
    return result
  }
}
