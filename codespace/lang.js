(() => {
  const storageKey = "popUpPassLang";
  const root = document.documentElement;
  const skipText = ".hero-art, .ascii-sign, .brand, script, style";
  const ja = {
    "Pop-Up Pass: Your pass to selling smarter": "Pop-Up Pass：もっと賢く売るためのパス",
    "Your pass to selling smarter. A free toolkit for artists and pop-up vendors.": "もっと賢く売るためのパス。アーティストとポップアップ出店者のための無料ツールキット。",
    "Pop-Up Pass home": "Pop-Up Pass ホーム",
    "Main navigation": "メインナビゲーション",
    "Floating convention vendor badge. Click the badge to flip it.": "イベント出店者用のバッジ。クリックすると裏返ります。",
    "Pop-Up Pass convention lanyard. Flip the badge to see Artist Alley, Small Business.": "Pop-Up Pass のネックストラップ。バッジを裏返すと Artist Alley と Small Business が表示されます。",
    "Pup, the Pop Up Pass mascot": "Pop Up Pass のマスコット、パップ",
    "Created by LK, CL, SG, and JG": "制作：LK、CL、SG、JG",
    "Seller type": "出店者のタイプ",
    "Your pocket pup.": "あなたのポケットパップ。",
    "Vendor toolkit": "出店者ツールキット",
    "Payment type": "支払い方法",
    "ABOUT": "紹介",
    "OUR STORY": "ストーリー",
    "INFO": "料金",
    "GET YOURS": "はじめる",
    "Made for the makers": "つくる人のために",
    "Your table.": "あなたのテーブル。",
    "Your": "あなたの",
    "big break.": "大きなチャンス。",
    "Your pocket-sized pal! The business toolkit for artists, con vendors, and pop-up dreamers. Price smarter, sell in a tap, and leave every event knowing what worked.": "ポケットサイズの相棒！アーティスト、イベント出店者、ポップアップを夢見る人のためのビジネスツールキットです。賢く価格を決めて、タップで販売を記録し、何がうまくいったかを把握してイベントを終えられます。",
    "Get your free pass": "無料パスをもらう",
    "Take a look": "見てみる",
    "Free to start · No login · Your data stays on your device": "無料で開始 · ログイン不要 · データはお使いの端末に保存",
    "The old way is exhausting": "これまでのやり方は大変",
    "You make the magic.": "魔法をつくるのはあなた。",
    "We’ll help with the math.": "計算はおまかせください。",
    "You deserve more than a cash box and a guess. Spend less time counting, more time making.": "現金箱と勘だけに頼る必要はありません。数える時間を減らして、つくる時間を増やしましょう。",
    "Pricing your work by real logistics, increasing your room to focus on the booth.": "実際のコストをもとに価格を決めて、ブースに集中できる余裕を増やせます。",
    "No more trying to track every sale on paper during a con. Your pocket pup does it for you.": "イベント中にすべての販売を紙に記録する必要はもうありません。ポケットパップにおまかせください。",
    "Now getting home and not having to worry about not knowing what actually sold.": "家に帰ってから、何が売れたのかわからず悩むこともなくなります。",
    "Four tiny superpowers": "4つの小さなスーパーパワー",
    "Big brand energy.": "大きなブランドの勢いを。",
    "One person shop made simple.": "ひとりのお店をシンプルに。",
    "Everything you need to run the table, all in one pocket-sized pass.": "テーブル運営に必要なものを、ポケットサイズのパスひとつに。",
    "Price Helper": "価格ヘルパー",
    "Turn material, time, and booth cost into a confident price and break-even goal.": "材料費、作業時間、ブース代から、自信を持てる価格と損益分岐の目標を出します。",
    "Table Tracker": "テーブルトラッカー",
    "Tap to sell, track cash or card, and spot the low-stock favorites in real time.": "タップで販売を記録し、現金とカードを管理して、在庫が少ない人気商品をリアルタイムで確認できます。",
    "Post & Flyer Maker": "投稿・チラシメーカー",
    "Give your best-seller its moment with a ready-to-share, shop-worthy post.": "すぐにシェアできる投稿で、人気商品を輝かせましょう。",
    "Trend Restock": "トレンド補充",
    "Fresh ideas for what to make next, matched to your shop and what’s selling.": "お店と売れ筋に合わせて、次につくるもののアイデアを提案します。",
    "From setup to sold out": "準備から完売まで",
    "A good day, in four small steps.": "いい一日を、4つの小さなステップで。",
    "Night before": "前日の夜",
    "Set your prices. Count your stock. Get some sleep.": "価格を決めて、在庫を数えて、しっかり眠りましょう。",
    "At the table": "テーブルで",
    "Tap to track each sale while you meet your people.": "お客さんと話しながら、タップで販売を記録します。",
    "Between rushes": "混雑の合間に",
    "Share a quick post of the thing everyone loves.": "みんなに人気の商品をさっと投稿しましょう。",
    "After the con": "イベントのあとに",
    "See what moved and what to make more of next.": "何が売れて、次に何を増やすべきかを確認します。",
    "A pass for every kind of maker": "すべてのつくる人のためのパス",
    "Your niche. Your next big idea.": "あなたのニッチ。次の大きなアイデア。",
    "Artists": "アーティスト",
    "Crafters": "クラフター",
    "Food Pop-Ups": "フードポップアップ",
    "Student sellers": "学生出店者",
    "New Moment": "新しい瞬間",
    "Try out a new set or collection. Fit your style and make your new fan favorites.": "新しいセットやコレクションを試してみましょう。あなたらしさを活かして、新しい人気商品をつくりましょう。",
    "Creative Detail": "クリエイティブなディテール",
    "From crochets to keychains, accessories make an easy, giftable collection.": "かぎ針編みからキーホルダーまで、アクセサリーは贈り物にしやすいコレクションになります。",
    "What’s in Season": "今が旬のもの",
    "A pretty specialty beverage or unique themed snack could be the next new trend.": "素敵な特製ドリンクやユニークなテーマのスナックが、次のトレンドになるかもしれません。",
    "Focus on the Trends": "トレンドに注目",
    "What’s old is new. Nostalgia is back, but so is pop culture. Find your niche for a fun, low-cost next drop.": "古いものが新しい時代です。懐かしさもポップカルチャーも戻ってきています。あなたのニッチを見つけて、楽しく低コストな次の新作をつくりましょう。",
    "Made with maker magic": "つくる人の魔法から生まれました",
    "We’ve been on your side of the table.": "私たちも、あなたと同じ側のテーブルにいました。",
    "“I started selling at conventions when I was nine. I know the excitement of a first sale, and the late-night math after. I wanted every young maker to feel like they had a whole team behind them.”": "「私は9歳のときにイベントで販売を始めました。初めて売れたときの喜びも、そのあと夜遅くまで続く計算も知っています。すべての若いつくり手に、チームがついていると感じてほしかったのです。」",
    "Lillian Kane · Artist, Designer, and Pop-Up Pass Founder": "Lillian Kane · アーティスト、デザイナー、Pop-Up Pass 創設者",
    "Good things grow together": "いいものは一緒に育つ",
    "Start free. Grow your way.": "無料で始めて、あなたのペースで成長を。",
    "Useful from your very first event. More room when you’re ready.": "最初のイベントから役立ちます。準備ができたら、さらに広げられます。",
    "Free pass": "無料パス",
    "Everything you need for your next event.": "次のイベントに必要なものがすべてそろいます。",
    "always": "ずっと無料",
    "Price helper + break-even math": "価格ヘルパー + 損益分岐の計算",
    "One active event & table tracker": "進行中のイベント1件とテーブルトラッカー",
    "Three post and flyer templates": "投稿・チラシのテンプレート3種類",
    "Get started →": "はじめる →",
    "For makers ready to keep the momentum.": "勢いを続けたいつくり手のために。",
    "/ month · coming soon": "/ 月 · 近日公開",
    "Unlimited events and sales history": "イベントと販売履歴が無制限",
    "All templates + saved brand kit": "全テンプレート + ブランドキットの保存",
    "Card sync and trend alerts": "カード連携とトレンド通知",
    "Try the demo →": "デモを試す →",
    "Collective": "コレクティブ",
    "Better together at a shared booth.": "共同ブースなら、一緒にもっと楽しく。",
    "Let’s talk": "ご相談ください",
    "Shared inventory for your group": "グループで共有する在庫",
    "Club and collective workspaces": "クラブや団体のワークスペース",
    "One table, one team": "ひとつのテーブル、ひとつのチーム",
    "Say hello →": "連絡する →",
    "Built for TechEquity 2026 · Made for the makers": "TechEquity 2026 のために制作 · つくる人のために",
    "Free mode keeps your data on this device. We never sell your sales data.": "無料モードではデータをこの端末に保存します。販売データを売ることは絶対にありません。",
    "● DEMO MODE": "● デモモード",
    "← Back to site": "← サイトに戻る",
    "Your toolkit": "ツールキット",
    "Home": "ホーム",
    "Price helper": "価格ヘルパー",
    "Table tracker": "テーブルトラッカー",
    "Create a post": "投稿をつくる",
    "Insights": "インサイト",
    "Your event": "あなたのイベント",
    "Anime Convention": "アニメコンベンション",
    "Today · Booth A-14": "本日 · ブース A-14",
    "Hey, maker.": "こんにちは、つくり手さん。",
    "Your table is looking good. Here’s the little picture so far.": "テーブルは順調です。ここまでの様子をご覧ください。",
    "Today’s sales": "本日の売上",
    "↗ Your first event is underway": "↗ 最初のイベントが進行中",
    "Items sold": "販売数",
    "Across your little shop": "お店全体で",
    "Stock to watch": "注意したい在庫",
    "♡ Almost sold out": "♡ もうすぐ売り切れ",
    "Fan Favorites": "ファンのお気に入り",
    "See all →": "すべて見る →",
    "Not So Popular": "あまり売れていない商品",
    "A little heads-up": "ちょっとしたお知らせ",
    "JUST NOW": "たった今",
    "Go to my table": "テーブルへ",
    "See my insights": "インサイトを見る",
    "Price with confidence.": "自信を持って価格を決めましょう。",
    "A fair price for your work, and a clear path to covering your table.": "作品にふさわしい価格と、出店費用を回収するまでの道筋がわかります。",
    "What are you pricing?": "何の価格を決めますか？",
    "Materials per item ($)": "1個あたりの材料費（$）",
    "Your time (minutes)": "作業時間（分）",
    "Maker time counts. We use $15/hour as a starting point.": "つくる時間にも価値があります。目安として時給 $15 で計算します。",
    "Your booth fee ($)": "ブース代（$）",
    "A sweet spot for your price": "おすすめの価格帯",
    "Your table, in a tap.": "あなたのテーブルを、ワンタップで。",
    "One little tap for every sale. We’ll keep count for you.": "販売ごとに軽くタップするだけ。数えるのはおまかせください。",
    "Cash": "現金",
    "Card": "カード",
    "Inventory": "在庫",
    "Tapped +1 sold by mistake? Use −1 sold to take it back. It removes one sale and returns the item to your stock.": "間違えて「+1 販売」を押しましたか？「−1 販売」で取り消せます。販売が1件減り、商品が在庫に戻ります。",
    "Make a little noise.": "ちょっと注目を集めましょう。",
    "Your best-seller deserves a post. Pick a look and make it yours.": "人気商品を投稿しましょう。デザインを選んで、あなたらしく仕上げてください。",
    "Choose your star": "主役を選ぶ",
    "Pick a template": "テンプレートを選ぶ",
    "Portrait post": "縦長の投稿",
    "Story": "ストーリー",
    "Booth flyer": "ブースのチラシ",
    "Write my caption": "キャプションをつくる",
    "↓ Save design": "↓ デザインを保存",
    "Demo uses ready-made captions and sample designs. No AI or social account is connected.": "デモでは用意されたキャプションとサンプルデザインを使用しています。AIやSNSアカウントには接続していません。",
    "MYBLENX STICKERS · MADE WITH LOVE": "MYBLENX ステッカー · 心をこめて",
    "Find your new favorite!": "新しいお気に入りを見つけよう！",
    "Look what you did.": "こんなに頑張りました。",
    "A little recap of your event, with ideas for the next one.": "イベントの振り返りと、次回に向けたアイデアです。",
    "Event earnings": "イベントの売上",
    "Anime Convention · today": "アニメコンベンション · 本日",
    "Your top seller": "一番の人気商品",
    "Little fan favorite": "ファンのお気に入り",
    "Room to experiment": "試す余地あり",
    "Keychains": "キーホルダー",
    "Try a new design": "新しいデザインを試しましょう",
    "Fresh from the trend board": "トレンドボードから",
    "CURATED STARTER IDEAS": "厳選スターターアイデア",
    "Frog & mushroom friends": "カエルとキノコの仲間たち",
    "Cozy little nature motifs pair perfectly with your sticker style.": "やさしい自然モチーフは、あなたのステッカーのスタイルにぴったりです。",
    "Strawberry milk moments": "いちごミルクのひととき",
    "Sweet colors and nostalgic treats are a lovely mini collection.": "甘い色と懐かしいお菓子は、素敵なミニコレクションになります。",
    "Black cat energy": "黒猫のパワー",
    "Make a companion to your best-seller with a playful twist.": "遊び心を加えて、人気商品の仲間をつくりましょう。",
    "Your Anime Convention recap": "アニメコンベンションの振り返り",
    "Demo insights use sample sales and a curated trend list; live social trend data isn’t connected.": "デモのインサイトはサンプルの販売データと厳選したトレンドリストを使用しています。SNSのリアルタイムのトレンドデータには接続していません。",
    "PUP Sticker": "PUP ステッカー",
    "Print": "プリント",
    "Print Mini": "プリント ミニ",
    "Moon keychain": "ムーンキーホルダー",
    "Enamel Pin": "エナメルピン",
    "Mini Print": "ミニプリント",
    "Logo Sticker": "ロゴステッカー",
    "{count} item": "{count}点",
    "{count} items": "{count}点",
    "{count} sold": "{count}個販売",
    "{count} left": "残り{count}個",
    "{count} in stock": "在庫{count}個",
    "{count} sold today": "本日{count}個販売",
    "You made {money} today. {name} is your table favorite, and you’ve got {stock} left. Try a frog-and-mushroom mini set for your next event. You’ve got this!": "本日の売上は{money}です。一番人気は{name}で、残りは{stock}個です。次のイベントではカエルとキノコのミニセットを試してみましょう。その調子です！",
    "You made {money} today. {name} is your table favorite, and it’s sold out. Try a frog-and-mushroom mini set for your next event. You’ve got this!": "本日の売上は{money}です。一番人気は{name}で、売り切れました。次のイベントではカエルとキノコのミニセットを試してみましょう。その調子です！",
    "Nothing’s running low.": "在庫が少ない商品はありません。",
    "{name} is almost gone.": "{name}はもうすぐなくなります。",
    "{name} is sold out.": "{name}は売り切れました。",
    "Your stock looks good. Keep those sales coming.": "在庫は十分です。この調子で販売を続けましょう。",
    "You’ve got {stock} left. Tap to log a sale or make a note to restock after the rush.": "残りは{stock}個です。タップして販売を記録するか、混雑のあとに補充するようメモしておきましょう。",
    "Make a note to restock after the rush.": "混雑のあとに補充するようメモしておきましょう。",
    "Change stock": "在庫を変更",
    "Stock for {name}": "{name}の在庫",
    "Remove one mistaken sale of {name}": "{name}の誤った販売を1件取り消す",
    "−1 sold": "−1 販売",
    "+1 sold": "+1 販売",
    "Sold out": "売り切れ",
    "Sell {count} at {price} to cover your {booth} table.": "{price}で{count}個売ると、{booth}のテーブル代を回収できます。",
    "Add your booth fee to see how many sales cover your table.": "ブース代を入力すると、回収に必要な販売数がわかります。",
    "{name} · 1 sale removed": "{name} · 販売を1件取り消しました",
    "{name} · {payment} sale added": "{name} · {payment}の販売を追加しました",
    "cash": "現金",
    "card": "カード",
    "Stock must be a whole number, 0 or more": "在庫は0以上の整数で入力してください",
    "{name} · stock set to {stock}": "{name} · 在庫を{stock}個に設定しました",
    "Couldn’t save on this device": "この端末に保存できませんでした",
    "Meet your new favorite {name}. Find me at Anime Convention, booth A-14! #artistalley #smallartist #animeconvention": "新しいお気に入り、{name}をご紹介します。アニメコンベンションのブース A-14 でお待ちしています！ #アーティストアレイ #小さなアーティスト #アニメコンベンション",
    "Your design is ready to save.": "デザインを保存できます。",
    "Switch to English": "英語に切り替える",
    "Switch to Japanese": "日本語に切り替える"
  };
  const textOriginals = new WeakMap();
  const labelOriginals = new WeakMap();
  const pageTitle = document.title;
  const description = document.querySelector('meta[name="description"]');
  const pageDescription = description ? description.content : "";
  const listeners = [];
  let lang = "en";

  const translated = text => lang === "ja" && ja[text] ? ja[text] : text;
  const t = (text, values = {}) => translated(text).replace(/\{(\w+)\}/g, (match, key) => key in values ? values[key] : match);

  function translateText(node) {
    if (!textOriginals.has(node)) textOriginals.set(node, node.nodeValue);
    const original = textOriginals.get(node);
    const key = original.trim();
    if (key) node.nodeValue = original.replace(key, translated(key));
  }
  function translatePage() {
    const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
    while (walker.nextNode()) {
      if (!walker.currentNode.parentElement.closest(skipText)) translateText(walker.currentNode);
    }
    document.querySelectorAll("[aria-label]:not([data-lang-toggle])").forEach(element => {
      if (!labelOriginals.has(element)) labelOriginals.set(element, element.getAttribute("aria-label"));
      element.setAttribute("aria-label", translated(labelOriginals.get(element)));
    });
    document.title = translated(pageTitle);
    if (description) description.content = translated(pageDescription);
  }
  function setLang(next) {
    lang = next === "ja" ? "ja" : "en";
    root.lang = lang;
    root.dataset.lang = lang;
    translatePage();
    document.querySelectorAll("[data-lang-toggle]").forEach(toggle => {
      toggle.querySelector(".lang-label").textContent = lang === "ja" ? "JP" : "EN";
      toggle.setAttribute("aria-pressed", String(lang === "ja"));
      toggle.setAttribute("aria-label", t(lang === "ja" ? "Switch to English" : "Switch to Japanese"));
    });
    try { localStorage.setItem(storageKey, lang); }
    catch (error) { console.warn("Could not save the language choice.", error); }
    listeners.forEach(listener => listener());
  }

  document.querySelectorAll("[data-lang-toggle]").forEach(toggle => toggle.addEventListener("click", () => setLang(lang === "ja" ? "en" : "ja")));
  let saved = null;
  try { saved = localStorage.getItem(storageKey); }
  catch (error) { console.warn("Could not load the language choice.", error); }
  setLang(saved);
  window.PopUpLang = { t, onChange: listener => listeners.push(listener), dictionary: ja };
})();
