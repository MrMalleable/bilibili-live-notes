## 爬虫第三篇：爬取CSDN首页推荐文章列表

### 1. 观察页面

![image-20210923223411182](C:\Users\ilovewl\AppData\Roaming\Typora\typora-user-images\image-20210923223411182.png)

从csdn首页可以看到，推荐这个文章列表，当你向下滑动鼠标滚轮的时候，你就会发现新的文章会不停地呈现出来。我们可以想一下，csdn肯定不会一下子把所有文章全部给你显示出来，你只需要不停地往下拖就能看到新文章，而是你向下滑动，会触发新的请求事件，向后台请求新的文章列表，动态渲染到前端，展示出来即可。



于是乎，基于这种猜想，我们F12打开浏览器的控制台，向下滑动滚轮，我们在网络请求中，可以看到下面这个请求，根据响应的json数据，我们就能判定出这个就是向后台请求新文章列表的接口。

![image-20210923224107473](C:\Users\ilovewl\AppData\Roaming\Typora\typora-user-images\image-20210923224107473.png)



分析上面这个json结构，我们发现每一篇文章的标题对应**title**字段，每一篇文章的访问链接对应**url**字段，所以我们就可以根据这个来编写代码



### 2. 编写代码

主要的思路：

- 请求特定的url:https://cms-api.csdn.net/v1/web_home/select_content?componentIds=www-recomend-community
- 获取到响应的json，封装成实体对象之后打印每篇文章的标题和链接即可。

下面看下代码：

```go
package main

import (
	"encoding/json"
	"fmt"
	"github.com/gocolly/colly"
	"log"
)

type CsdnResponse struct {
	Code int `json:"code"`
	Data Data `json:"data"`
}

type Data struct {
	WwwRecommendCommunity RecommendCommunity `json:"www-recomend-community"`
}

type RecommendCommunity struct {
	Info []Info `json:"info"`
}

type Info struct {
	Extend Extend `json:"extend"`
}

type Extend struct{
	Title string `json:"title"`
	Url string `json:"url"`
}

func main() {
	c := colly.NewCollector(
		// 允许链接重新访问，这里不设置的话默认https://cms-api.csdn.net/v1/web_home/select_content?componentIds=www-recomend-community
		// 只会访问一次
		colly.AllowURLRevisit(),
		colly.UserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.82 Safari/537.36 Edg/93.0.961.52"),
	)
	c.OnError(func(_ *colly.Response, err error) {
		log.Println("Something went wrong:", err)
	})
	// 请求返回数据之后的回调
	c.OnResponse(func(r *colly.Response) {
		var csdn = &CsdnResponse{}
		// 将响应封装成实体对象
		err := json.Unmarshal(r.Body, &csdn)
		if err != nil {
			fmt.Println("json parse error:", err)
			return
		}
		for _, info := range csdn.Data.WwwRecommendCommunity.Info {
			fmt.Println("文章标题为：", info.Extend.Title)
			fmt.Println("文章链接为：", info.Extend.Url)
			fmt.Println()
		}
	})
	// 请求5次获取新文章列表
	for i := 1; i < 5; i++ {
		c.Visit("https://cms-api.csdn.net/v1/web_home/select_content?componentIds=www-recomend-community")
	}
}
```



### 3. 运行效果

![image-20210923224906420](C:\Users\ilovewl\AppData\Roaming\Typora\typora-user-images\image-20210923224906420.png)

观察上面的运行结果，我们知道这种文章标题会出现空的情况，这种你点进去这个访问链接发现其实这是一条动态，没有标题的，所以如果需要筛选的话，我觉得可以根据链接是否包含blink.csdn.net来判别这是不是一个动态。



以上就是整篇爬虫的主要内容，最近思来想去，不知道爬虫内容要讲些什么东西比较好，如果有什么比较有意思的爬虫欢迎在评论区留言，我可以golang或者其他语言来试试自己能不能实现这个爬虫，毕竟接受挑战才是生活中一件有意义的事情。



可能我现在很菜，但我也不能保证未来的我不会更菜，特别欢迎有兴趣的小伙伴和我一起交流探讨啊，一起进步啊。



谢谢啦，别忘记一键三连了！（手动狗头）
