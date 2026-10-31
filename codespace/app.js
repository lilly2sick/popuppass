    (() => {
      const sampleItems = [
        { id: "cat-sticker", name: "PUP Sticker", mark: "PUP", price: 7, stock: 2, sold: 4 },
        { id: "frog-print", name: "Print", mark: "PRINT", price: 20, stock: 8, sold: 1 },
        { id: "miku-print-mini", name: "Print Mini", mark: "MINI", price: 12, stock: 8, sold: 0 },
        { id: "moon-keychain", name: "Moon keychain", mark: "MOON", price: 10, stock: 5, sold: 0 },
        { id: "berry-pin", name: "Enamel Pin", mark: "PIN", price: 9, stock: 12, sold: 0 },
        { id: "star-print", name: "Mini Print", mark: "MINI", price: 15, stock: 6, sold: 0 },
        { id: "mushroom-sticker", name: "Logo Sticker", mark: "LOGO", price: 6, stock: 10, sold: 0 }
      ];
      const storageKey = "popUpPassDemoV2";
      let items = sampleItems;
      let sales = [];
      let payment = "Cash";
      let inventoryMode = false;
      let activeAudience = "artist";
      let captionItem = null;
      let activeTemplate = "portrait";
      let toastTimer;
      let badgeFlipped = false;
      let badgeScrolledPast = false;
      let badgeSwingAnimation = null;
      const motionPreference = window.matchMedia("(prefers-reduced-motion: reduce)");
      try {
        const saved = JSON.parse(localStorage.getItem(storageKey) || "null");
        if (saved && Array.isArray(saved.items) && Array.isArray(saved.sales)) {
          items = sampleItems.map(sample => {
            const savedItem = saved.items.find(item => item.id === sample.id);
            return {
              ...sample,
              stock: savedItem && Number.isInteger(savedItem.stock) && savedItem.stock >= 0 ? savedItem.stock : sample.stock,
              sold: savedItem && Number.isInteger(savedItem.sold) && savedItem.sold >= 0 ? savedItem.sold : sample.sold
            };
          });
          sales = saved.sales.filter(sale => items.some(item => item.id === sale.id) && Number.isFinite(sale.price) && (sale.payment === "Cash" || sale.payment === "Card"));
        }
      } catch (error) {
        console.warn("Could not load the saved Pop-Up Pass demo.", error);
      }

      const { t, onChange: onLanguageChange } = window.PopUpLang;
      const itemName = item => t(item.name);
      const qs = (selector, root = document) => root.querySelector(selector);
      const qsa = (selector, root = document) => [...root.querySelectorAll(selector)];
      const money = amount => `$${amount.toFixed(2).replace(/\.00$/, "")}`;
      const roundCents = amount => Math.round(amount * 100) / 100;
      const totalRevenue = () => items.reduce((sum, item) => sum + Math.round(item.price * 100) * item.sold, 0) / 100;
      const totalSold = () => items.reduce((sum, item) => sum + item.sold, 0);
      const topSeller = () => items.reduce((top, item) => item.sold > top.sold ? item : top);
      function persist() {
        try { localStorage.setItem(storageKey, JSON.stringify({ items, sales })); }
        catch (error) { console.warn("Could not save the Pop-Up Pass demo.", error); showToast(t("Couldn’t save on this device")); }
      }
      function showToast(message) {
        const toast = qs("#toast");
        toast.textContent = message;
        toast.classList.add("show");
        clearTimeout(toastTimer);
        toastTimer = setTimeout(() => toast.classList.remove("show"), 2300);
      }
      function flipBadge(flipped = !badgeFlipped) {
        if (badgeFlipped === flipped) return;
        badgeFlipped = flipped;
        const badge = qs("#badgeCard");
        qs("#badgeFlip").setAttribute("aria-pressed", String(flipped));
        if (typeof window.anime === "function" && !motionPreference.matches) {
          window.anime.remove(badge);
          window.anime({
            targets: badge,
            rotateY: flipped ? 180 : 0,
            scale: [1, 1.035, 1],
            duration: 1050,
            easing: "easeInOutSine"
          });
        } else {
          badge.style.transform = `rotateY(${flipped ? 180 : 0}deg)`;
        }
      }
      function startBadgeMotion() {
        if (typeof window.anime !== "function" || motionPreference.matches) return;
        document.documentElement.classList.add("anime-ready");
        if (!badgeSwingAnimation) {
          badgeSwingAnimation = window.anime({
            targets: "#badgeFlip",
            rotate: ["-4deg", "4deg"],
            duration: 2500,
            direction: "alternate",
            easing: "easeInOutSine",
            loop: true
          });
        }
        window.anime({
          targets: ".hero-copy-block > *",
          opacity: [0, 1],
          translateY: [18, 0],
          duration: 720,
          delay: window.anime.stagger(95),
          easing: "easeOutCubic"
        });
        if ("IntersectionObserver" in window) {
          const revealObserver = new IntersectionObserver(entries => {
            entries.forEach(entry => {
              if (!entry.isIntersecting) return;
              revealObserver.unobserve(entry.target);
              window.anime({
                targets: entry.target,
                opacity: [0, 1],
                translateY: [20, 0],
                duration: 700,
                easing: "easeOutCubic"
              });
            });
          }, { threshold: 0.16 });
          qsa(".problem, .feature, .time-card, .trend-showcase, .story-box, .price-card").forEach(card => revealObserver.observe(card));
        }
      }
      function openApp(tab = "home") {
        qs("#site").style.display = "none";
        qs("#app").classList.add("active");
        document.body.scrollTop = 0;
        window.scrollTo(0, 0);
        setTab(tab);
      }
      function setTab(tab) {
        qsa(".tab-button").forEach(button => button.classList.toggle("active", button.dataset.tab === tab));
        qsa(".app-view").forEach(view => view.classList.toggle("active", view.id === `view-${tab}`));
      }
      function render() {
        qs("#totalSales").textContent = money(totalRevenue());
        qs("#insightEarnings").textContent = money(totalRevenue());
        qs("#totalItems").textContent = totalSold();
        const lowStock = items.filter(item => item.stock <= 2).length;
        qs("#lowStockTotal").textContent = t(lowStock === 1 ? "{count} item" : "{count} items", { count: lowStock });
        const top = topSeller();
        qs("#topSeller").textContent = itemName(top);
        qs("#reportText").textContent = t(top.stock > 0 ? "You made {money} today. {name} is your table favorite, and you’ve got {stock} left. Try a frog-and-mushroom mini set for your next event. You’ve got this!" : "You made {money} today. {name} is your table favorite, and it’s sold out. Try a frog-and-mushroom mini set for your next event. You’ve got this!", { money: money(totalRevenue()), name: itemName(top), stock: top.stock });
        const lowest = items.filter(item => item.stock <= 2).sort((a, b) => a.stock - b.stock)[0];
        qs("#alertTitle").textContent = !lowest ? t("Nothing’s running low.") : t(lowest.stock > 0 ? "{name} is almost gone." : "{name} is sold out.", { name: itemName(lowest) });
        qs("#alertText").textContent = !lowest ? t("Your stock looks good. Keep those sales coming.") : lowest.stock > 0 ? t("You’ve got {stock} left. Tap to log a sale or make a note to restock after the rush.", { stock: lowest.stock }) : t("Make a note to restock after the rush.");
        const inventoryRows = list => list.map(item => `<div class="inventory-row"><span class="item-art">${item.mark}</span><span><strong>${itemName(item)}</strong><small>${money(item.price)} · ${t("{count} sold", { count: item.sold })}</small></span><span class="stock-count ${item.stock <= 2 ? "low" : ""}">${t("{count} left", { count: item.stock })}</span></div>`).join("");
        const bySold = [...items].sort((a, b) => b.sold - a.sold);
        const favorites = bySold.filter(item => item.sold > 0).slice(0, 3);
        const notPopular = bySold.filter(item => !favorites.includes(item)).slice(-3).reverse();
        qs("#homeInventory").innerHTML = inventoryRows(favorites);
        qs("#homeNotPopular").innerHTML = inventoryRows(notPopular);
        qs("#itemGrid").innerHTML = items.map(item => `<article class="sell-card"><div class="sell-art"><span>${item.mark}</span></div><strong>${itemName(item)}</strong><small>${money(item.price)} · <span class="${item.stock <= 2 ? "stock-count low" : ""}">${t("{count} in stock", { count: item.stock })}</span></small>${inventoryMode ? `<label class="stock-edit">${t("Change stock")}<input type="number" min="0" step="1" inputmode="numeric" data-stock="${item.id}" value="${item.stock}" aria-label="${t("Stock for {name}", { name: itemName(item) })}"></label>` : ""}<div class="sell-actions"><span style="font-size:10px;color:#92919e">${t("{count} sold today", { count: item.sold })}</span>${inventoryMode ? "" : `<button class="undo-sale" data-undo="${item.id}" aria-label="${t("Remove one mistaken sale of {name}", { name: itemName(item) })}" ${item.sold <= 0 ? "disabled" : ""}>${t("−1 sold")}</button><button data-sell="${item.id}" ${item.stock <= 0 ? "disabled" : ""}>${t(item.stock <= 0 ? "Sold out" : "+1 sold")}</button>`}</div></article>`).join("");
        const chosenItem = qs("#postItem").value;
        qs("#postItem").innerHTML = items.map(item => `<option value="${item.id}" ${item.id === chosenItem ? "selected" : ""}>${itemName(item)}</option>`).join("");
        updatePostPreview();
      }
      function updatePostPreview() {
        const item = items.find(entry => entry.id === qs("#postItem").value) || items[0];
        qs("#previewMark").textContent = item.mark;
        qs("#previewName").textContent = itemName(item);
        qs("#postPreview").classList.toggle("story", activeTemplate === "story");
        qs("#postPreview").classList.toggle("flyer", activeTemplate === "flyer");
      }
      function updatePrice() {
        const material = Math.max(0, Number(qs("#materialCost").value) || 0);
        const minutes = Math.max(0, Number(qs("#workMinutes").value) || 0);
        const booth = Math.max(0, Number(qs("#boothFee").value) || 0);
        const cost = roundCents(material + minutes / 60 * 15);
        const low = Math.ceil(roundCents(cost * 2));
        const high = Math.ceil(roundCents(cost * 2.5));
        const midpoint = Math.round(((low + high) / 2) * 100) / 100;
        qs("#suggestedPrice").textContent = `${money(low)}–${money(high)}`;
        const count = midpoint > 0 ? Math.ceil(booth / midpoint) : 0;
        qs("#breakEven").textContent = count > 0
          ? t("Sell {count} at {price} to cover your {booth} table.", { count, price: money(midpoint), booth: money(booth) })
          : t("Add your booth fee to see how many sales cover your table.");
      }
      qsa("[data-open-app]").forEach(button => button.addEventListener("click", () => openApp()));
      qs("#badgeFlip").addEventListener("click", () => flipBadge());
      if (window.history && "scrollRestoration" in window.history) window.history.scrollRestoration = "manual";
      window.addEventListener("scroll", () => {
        const scrolledPast = window.scrollY > 115;
        if (scrolledPast !== badgeScrolledPast) {
          badgeScrolledPast = scrolledPast;
          flipBadge(scrolledPast);
        }
      }, { passive: true });
      qsa(".tab-button").forEach(button => button.addEventListener("click", () => setTab(button.dataset.tab)));
      qsa("[data-goto]").forEach(button => button.addEventListener("click", () => setTab(button.dataset.goto)));
      qs("#backToSite").addEventListener("click", () => {
        qs("#app").classList.remove("active");
        qs("#site").style.display = "";
        window.scrollTo(0, 0);
      });
      qs("#itemGrid").addEventListener("click", event => {
        if (inventoryMode) return;
        const undoButton = event.target.closest("[data-undo]");
        if (undoButton) {
          const item = items.find(entry => entry.id === undoButton.dataset.undo);
          if (!item || item.sold <= 0) return;
          item.stock += 1;
          item.sold -= 1;
          const lastSale = sales.map(sale => sale.id).lastIndexOf(item.id);
          if (lastSale >= 0) sales.splice(lastSale, 1);
          persist();
          render();
          showToast(t("{name} · 1 sale removed", { name: itemName(item) }));
          return;
        }
        const button = event.target.closest("[data-sell]");
        if (!button) return;
        const item = items.find(entry => entry.id === button.dataset.sell);
        if (!item || item.stock <= 0) return;
        item.stock -= 1;
        item.sold += 1;
        sales.push({ id: item.id, price: item.price, payment });
        persist();
        render();
        showToast(t("{name} · {payment} sale added", { name: itemName(item), payment: t(payment.toLowerCase()) }));
      });
      qs("#itemGrid").addEventListener("change", event => {
        const input = event.target.closest("[data-stock]");
        if (!input) return;
        const item = items.find(entry => entry.id === input.dataset.stock);
        if (!item) return;
        const stock = Number(input.value);
        if (input.value.trim() === "" || !Number.isInteger(stock) || stock < 0) {
          render();
          showToast(t("Stock must be a whole number, 0 or more"));
          return;
        }
        item.stock = stock;
        persist();
        render();
        showToast(t("{name} · stock set to {stock}", { name: itemName(item), stock }));
      });
      function setInventoryMode(on) {
        inventoryMode = on;
        qs("#inventoryButton").classList.toggle("active", on);
        qs("#inventoryButton").setAttribute("aria-pressed", String(on));
        qsa("[data-payment]").forEach(option => {
          const active = !on && option.dataset.payment === payment;
          option.classList.toggle("active", active);
          option.setAttribute("aria-pressed", String(active));
        });
        render();
      }
      qs("#inventoryButton").addEventListener("click", () => setInventoryMode(!inventoryMode));
      qsa("[data-payment]").forEach(button => button.addEventListener("click", () => {
        payment = button.dataset.payment;
        setInventoryMode(false);
      }));
      ["materialCost", "workMinutes", "boothFee"].forEach(id => qs(`#${id}`).addEventListener("input", updatePrice));
      qs("#postItem").addEventListener("change", updatePostPreview);
      qsa("[data-template]").forEach(button => button.addEventListener("click", () => {
        activeTemplate = button.dataset.template;
        qsa("[data-template]").forEach(option => option.classList.toggle("active", option === button));
        updatePostPreview();
      }));
      function renderCaption() {
        if (captionItem) qs("#captionOutput").textContent = t("Meet your new favorite {name}. Find me at Anime Convention, booth A-14! #artistalley #smallartist #animeconvention", { name: itemName(captionItem).toLowerCase() });
      }
      qs("#captionButton").addEventListener("click", () => {
        captionItem = items.find(entry => entry.id === qs("#postItem").value) || items[0];
        renderCaption();
      });
      qs("#downloadButton").addEventListener("click", () => {
        const item = items.find(entry => entry.id === qs("#postItem").value) || items[0];
        const colors = activeTemplate === "story" ? ["#c1b3ff", "#7bdcff"] : activeTemplate === "flyer" ? ["#ffb36b", "#a899ff"] : ["#ff9bdc", "#a899ff"];
        const height = { portrait: 1350, story: 1920, flyer: 1080 }[activeTemplate];
        const middle = height / 2;
        const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="${height}" viewBox="0 0 1080 ${height}"><defs><linearGradient id="g" x2="1" y2="1"><stop stop-color="${colors[0]}"/><stop offset="1" stop-color="${colors[1]}"/></linearGradient></defs><rect width="1080" height="${height}" fill="url(#g)"/><text x="540" y="${activeTemplate === "story" ? 300 : 170}" text-anchor="middle" font-family="Arial,'Yu Gothic','Hiragino Sans','Noto Sans JP',sans-serif" font-size="38" font-weight="700" letter-spacing="8" fill="#191624">MYBLENX STICKERS</text><text x="540" y="${middle + 50}" text-anchor="middle" font-family="Arial,'Yu Gothic','Hiragino Sans','Noto Sans JP',sans-serif" font-size="100" font-weight="700" letter-spacing="12" fill="#191624">${item.mark}</text><text x="540" y="${middle + 220}" text-anchor="middle" font-family="Arial,'Yu Gothic','Hiragino Sans','Noto Sans JP',sans-serif" font-size="68" font-weight="700" fill="#191624">${itemName(item).replace(/[&<>"]/g, "")}</text><text x="540" y="${middle + 300}" text-anchor="middle" font-family="Arial,'Yu Gothic','Hiragino Sans','Noto Sans JP',sans-serif" font-size="34" fill="#191624">${t("Find your new favorite!")}</text></svg>`;
        const link = document.createElement("a");
        link.href = URL.createObjectURL(new Blob([svg], { type: "image/svg+xml" }));
        link.download = "pop-up-pass-post.svg";
        link.click();
        URL.revokeObjectURL(link.href);
        showToast(t("Your design is ready to save."));
      });
      const trends = {
        artist: ["A", "New Moment", "Try out a new set or collection. Fit your style and make your new fan favorites."],
        crafter: ["C", "Creative Detail", "From crochets to keychains, accessories make an easy, giftable collection."],
        food: ["F", "What’s in Season", "A pretty specialty beverage or unique themed snack could be the next new trend."],
        student: ["S", "Focus on the Trends", "What’s old is new. Nostalgia is back, but so is pop culture. Find your niche for a fun, low-cost next drop."]
      };
      function renderAudience() {
        const [mark, title, copy] = trends[activeAudience];
        qs("#audienceTrend").innerHTML = `<div class="trend-mark">${mark}</div><div><strong>${t(title)}</strong><p>${t(copy)}</p></div>`;
      }
      qsa("[data-audience]").forEach(button => button.addEventListener("click", () => {
        activeAudience = button.dataset.audience;
        qsa("[data-audience]").forEach(option => {
          const active = option === button;
          option.classList.toggle("active", active);
          option.setAttribute("aria-selected", String(active));
        });
        renderAudience();
      }));
      function applyMotionPreference(event) {
        document.documentElement.classList.toggle("motion-off", event.matches);
        if (event.matches && badgeSwingAnimation) {
          badgeSwingAnimation.pause();
          badgeSwingAnimation = null;
          qs("#badgeFlip").style.transform = "rotate(0deg)";
        } else {
          startBadgeMotion();
        }
      }
      const asciiFont = {
        C: [".###", "#...", "#...", "#...", ".###"],
        E: ["####", "#...", "###.", "#...", "####"],
        K: ["#..#", "#.#.", "##..", "#.#.", "#..#"],
        O: [".##.", "#..#", "#..#", "#..#", ".##."],
        P: ["###.", "#..#", "###.", "#...", "#..."],
        R: ["###.", "#..#", "###.", "#.#.", "#..#"],
        T: ["####", ".##.", ".##.", ".##.", ".##."],
        U: ["#..#", "#..#", "#..#", "#..#", ".##."],
        Y: ["#..#", "#..#", ".##.", ".##.", ".##."],
        " ": ["..", "..", "..", "..", ".."]
      };
      const asciiRamp = "#@%&8$";
      const asciiRows = text => asciiFont.P.map((_, row) => [...text].map(letter => asciiFont[letter][row]).join("."));
      const taglineRows = asciiRows("YOUR POCKET PUP");
      const paintAscii = (rows, frame) => rows.map((row, y) => [...row].map((cell, x) => {
        if (cell !== "#") return " ";
        if (motionPreference.matches) return "#";
        return asciiRamp[Math.round((Math.sin(x * .45 + y * .7 - frame * .5) + 1) / 2 * (asciiRamp.length - 1))];
      }).join("")).join("\n");
      const asciiPup = frame => {
        const still = motionPreference.matches;
        const eyes = !still && frame % 32 >= 30 ? "- -" : "0 0";
        const tail = !still && Math.floor(frame / 3) % 2 ? "/" : "~";
        return ["  /^ ^\\", ` / ${eyes} \\`, " V\\ Y /V", "  / - \\", " /    |", `V__) ||${tail}`].join("\n");
      };
      let asciiFrame = 0;
      let asciiVisible = !("IntersectionObserver" in window);
      function drawAscii() {
        qs("#asciiTagline").textContent = paintAscii(taglineRows, asciiFrame);
        qs("#asciiPup").textContent = asciiPup(asciiFrame);
      }
      if ("IntersectionObserver" in window) {
        new IntersectionObserver(entries => { asciiVisible = entries[0].isIntersecting; }).observe(qs(".ascii-sign"));
      }
      setInterval(() => {
        if (!asciiVisible || document.hidden || motionPreference.matches) return;
        asciiFrame += 1;
        drawAscii();
      }, 110);
      drawAscii();
      if (motionPreference.addEventListener) motionPreference.addEventListener("change", drawAscii);
      applyMotionPreference(motionPreference);
      if (motionPreference.addEventListener) motionPreference.addEventListener("change", applyMotionPreference);
      function renderLanguage() {
        const nameField = qs("#itemName");
        if (nameField.value === "PUP Sticker" || nameField.value === window.PopUpLang.dictionary["PUP Sticker"]) nameField.value = t("PUP Sticker");
        render();
        updatePrice();
        renderAudience();
        renderCaption();
      }
      onLanguageChange(renderLanguage);
      renderLanguage();
    })();
