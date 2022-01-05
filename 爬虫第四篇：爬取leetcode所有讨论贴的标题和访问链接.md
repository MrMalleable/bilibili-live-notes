## 爬虫第四篇：爬取leetcode所有讨论贴的标题和访问链接

还是老样子，写一个爬虫，首先你需要知道你的目标数据是什么？你要如何才能获取到这些数据？你最后期望怎么来处理这些数据？

其实，和爬取牛客面经一样的思路，我这里想把leetcode网站的讨论贴给全部爬下来，于是我们有了目标，我们就得去实现它。 

所以打开https://leetcode-cn.com，我们得分析分析页面的数据是怎么来的。

![image-20210923232034247](C:\Users\ilovewl\AppData\Roaming\Typora\typora-user-images\image-20210923232034247.png)

下面讨论贴的文章列表肯定是分页展示的，你可以打开浏览器控制台，清空所有请求之后，你点击下一页之后你可以看到如上图所示的这个请求，打开返回的响应数据，这是一个json格式的数据，能够看到每一篇帖子的标题就能获取到。

关于帖子的链接是如何获取到的呢，你可以随便点击一篇帖子，就会发现最后帖子的访问链接和这个uuid紧密相连。



我们可以知道这是使用graphql向后台请求数据的，肯定会带请求参数，关于graphql的使用，其实我也不会，这让我想到了我下一篇动态应该写什么内容哈哈哈。我们来看下请求参数：

```json
{
  "operationName": "qaQuestionList",
  "variables": {
    "subjectSlug": "interview",
    "isFeatured": false,
    "pageNum": 2,
    "query": "",
    "tags": [],
    "sortType": "HOTTEST"
  },
  "query": "query qaQuestionList($subjectSlug: String!, $isFeatured: Boolean!, $query: String, $pageNum: Int, $tags: [String!], $sortType: CircleSortTypeEnum) {\n  qaQuestionList(subjectSlug: $subjectSlug, isFeatured: $isFeatured, query: $query, pageNum: $pageNum, filterTagSlugs: $tags, sortType: $sortType) {\n    totalNum\n    pageSize\n    nodes {\n      ...qaQuestion\n      __typename\n    }\n    __typename\n  }\n}\n\nfragment qaQuestion on QAQuestionNode {\n  uuid\n  slug\n  title\n  thumbnail\n  summary\n  content\n  sunk\n  pinned\n  pinnedGlobally\n  byLeetcode\n  isRecommended\n  isRecommendedGlobally\n  subscribed\n  hitCount\n  numAnswers\n  numPeopleInvolved\n  numSubscribed\n  createdAt\n  updatedAt\n  status\n  identifier\n  resourceType\n  articleType\n  alwaysShow\n  alwaysExpand\n  score\n  favoriteCount\n  isMyFavorite\n  isAnonymous\n  canEdit\n  reactionType\n  reactionsV2 {\n    count\n    reactionType\n    __typename\n  }\n  tags {\n    name\n    nameTranslated\n    slug\n    imgUrl\n    tagType\n    __typename\n  }\n  subject {\n    slug\n    title\n    __typename\n  }\n  contentAuthor {\n    ...contentAuthor\n    __typename\n  }\n  realAuthor {\n    ...realAuthor\n    __typename\n  }\n  __typename\n}\n\nfragment contentAuthor on ArticleAuthor {\n  username\n  userSlug\n  realName\n  avatar\n  __typename\n}\n\nfragment realAuthor on UserNode {\n  username\n  profile {\n    userSlug\n    realName\n    userAvatar\n    __typename\n  }\n  __typename\n}\n"
}
```

关于graphql的查询格式我们不去管，我凭借直觉发现只需要改变这个pageNum就可以请求不同页的帖子列表。

于是乎，代码搞起来。



### 代码

关于代码，在注释里面都有，如果还有不懂的欢迎评论区diss我。

```go
package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"time"
)

//爬取leetcode讨论贴

//响应的实体类
type LeetCodeResponse struct {
	Data DataResponse `json:"data"`
}

type DataResponse struct {
	QaQuestionList QuestionResponse `json:"qaQuestionList"`
}

type QuestionResponse struct{
	TotalNum int `json:"totalNum"`
	PageSize int `json:"pageSize"`
	Nodes []Node `json:"nodes"`
}

//帖子的格式为https://leetcode-cn.com/circle/discuss/${uuid}/
type Node struct {
	//帖子的唯一标识
	Uuid string `json:"uuid"`
	//帖子的标题
	Title string `json:"title"`
}

func main(){
	//一共1849/15=124页，页数的标号是从0开始计算的
	for i:= 0; i < 124; i++{
		// 试一下会不会反爬
		fmt.Println(">>>>>>>>开始爬取第", i, "页<<<<<<<")
		GetPageData(i)
		// 先加上个延时吧 0.5s
		time.Sleep(500*time.Millisecond)
	}
}

// 获取每一页的请求
func GetPageData(page int) {
	// graphql请求体，只需要改变页数
	requestBody := fmt.Sprintf(`{
  "operationName": "qaQuestionList",
  "variables": {
    "subjectSlug": "interview",
    "isFeatured": false,
    "pageNum": %d,
    "query": "",
    "tags": [],
    "sortType": "HOTTEST"
  },
  "query": "query qaQuestionList($subjectSlug: String!, $isFeatured: Boolean!, $query: String, $pageNum: Int, $tags: [String!], $sortType: CircleSortTypeEnum) {\n  qaQuestionList(subjectSlug: $subjectSlug, isFeatured: $isFeatured, query: $query, pageNum: $pageNum, filterTagSlugs: $tags, sortType: $sortType) {\n    totalNum\n    pageSize\n    nodes {\n      ...qaQuestion\n      __typename\n    }\n    __typename\n  }\n}\n\nfragment qaQuestion on QAQuestionNode {\n  uuid\n  slug\n  title\n  thumbnail\n  summary\n  content\n  sunk\n  pinned\n  pinnedGlobally\n  byLeetcode\n  isRecommended\n  isRecommendedGlobally\n  subscribed\n  hitCount\n  numAnswers\n  numPeopleInvolved\n  numSubscribed\n  createdAt\n  updatedAt\n  status\n  identifier\n  resourceType\n  articleType\n  alwaysShow\n  alwaysExpand\n  score\n  favoriteCount\n  isMyFavorite\n  isAnonymous\n  canEdit\n  reactionType\n  reactionsV2 {\n    count\n    reactionType\n    __typename\n  }\n  tags {\n    name\n    nameTranslated\n    slug\n    imgUrl\n    tagType\n    __typename\n  }\n  subject {\n    slug\n    title\n    __typename\n  }\n  contentAuthor {\n    ...contentAuthor\n    __typename\n  }\n  realAuthor {\n    ...realAuthor\n    __typename\n  }\n  __typename\n}\n\nfragment contentAuthor on ArticleAuthor {\n  username\n  userSlug\n  realName\n  avatar\n  __typename\n}\n\nfragment realAuthor on UserNode {\n  username\n  profile {\n    userSlug\n    realName\n    userAvatar\n    __typename\n  }\n  __typename\n}\n"
}`, page)

	var jsonStr = []byte(requestBody)
	var url = "https://leetcode-cn.com/graphql/"
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonStr))
	req.Header.Set("Content-Type", "application/json")
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		fmt.Println("请求时发生错误： ", err)
		return
	}
	defer resp.Body.Close()
	body, _ := ioutil.ReadAll(resp.Body)
	var res = &LeetCodeResponse{}
	err = json.Unmarshal(body, &res)
	if err != nil{
		fmt.Println("解析响应字符串出错： ", err)
		return
	}
	// 遍历响应，打印出每个帖子的标题和访问链接
	for _,question := range res.Data.QaQuestionList.Nodes{
		fmt.Println("帖子标题为：", question.Title)
		fmt.Printf("https://leetcode-cn.com/circle/discuss/%s/",question.Uuid)
		fmt.Println()
	}
}
```



又一篇爬虫写完了，说实话已经不知道下一篇爬虫要写啥比较好呢，总得一步步增加难度吧，不然和咸鱼有什么区别哈哈哈哈。



总的来说，这篇爬虫和上一篇爬虫差不多，列表的请求都是请求后台去动态渲染的，不同的是我们从接口格式了解到leetcode官方竟然是使用graphql来定义restful接口，后面有必要专门写篇文章来看看graphql这个东西到底咋用的。



小伙伴们，别忘了一键三连啊，多谢！