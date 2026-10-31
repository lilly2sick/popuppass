    (() => {
      const sampleItems = [
        { id: "cat-sticker", name: "Kuroneko Sticker", mark: "CAT", price: 7, stock: 2, sold: 4 },
        { id: "frog-print", name: "Miku Print", mark: "MIKU", price: 20, stock: 8, sold: 1 },
        { id: "miku-print-mini", name: "Miku Print Mini", mark: "MINI", price: 12, stock: 8, sold: 0 },
        { id: "moon-keychain", name: "Moon keychain", mark: "MOON", price: 10, stock: 5, sold: 0 },
        { id: "berry-pin", name: "Berry enamel pin", mark: "BERRY", price: 9, stock: 12, sold: 0 },
        { id: "star-print", name: "Starry mini print", mark: "STAR", price: 15, stock: 6, sold: 0 },
        { id: "mushroom-sticker", name: "Mushroom sticker", mark: "MUSH", price: 6, stock: 10, sold: 0 }
      ];
      const storageKey = "popUpPassDemoV2";
      let items = sampleItems;
      let sales = [];
      let payment = "Cash";
      let activeTemplate = "square";
      let toastTimer;
      let badgeFlipped = false;
      let scrollRevealComplete = false;
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

      const qs = (selector, root = document) => root.querySelector(selector);
      const qsa = (selector, root = document) => [...root.querySelectorAll(selector)];
      const money = amount => `$${amount.toFixed(2).replace(/\.00$/, "")}`;
      const roundCents = amount => Math.round(amount * 100) / 100;
      const totalRevenue = () => items.reduce((sum, item) => sum + Math.round(item.price * 100) * item.sold, 0) / 100;
      const totalSold = () => items.reduce((sum, item) => sum + item.sold, 0);
      const topSeller = () => items.reduce((top, item) => item.sold > top.sold ? item : top);
      function persist() {
        try { localStorage.setItem(storageKey, JSON.stringify({ items, sales })); }
        catch (error) { console.warn("Could not save the Pop-Up Pass demo.", error); showToast("Couldn’t save on this device"); }
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
        qs("#lowStockTotal").textContent = `${lowStock} ${lowStock === 1 ? "item" : "items"}`;
        const top = topSeller();
        qs("#topSeller").textContent = top.name;
        qs("#reportText").textContent = `You made ${money(totalRevenue())} today. ${top.name} is your table favorite, and ${top.stock > 0 ? `you’ve got ${top.stock} left` : "it’s sold out"}. Try a frog-and-mushroom mini set for your next event. You’ve got this!`;
        const lowest = items.filter(item => item.stock <= 2).sort((a, b) => a.stock - b.stock)[0];
        qs("#alertTitle").textContent = !lowest ? "Nothing’s running low." : lowest.stock > 0 ? `${lowest.name} is almost gone.` : `${lowest.name} is sold out.`;
        qs("#alertText").textContent = !lowest ? "Your stock looks good. Keep those sales coming." : lowest.stock > 0 ? `You’ve got ${lowest.stock} left. Tap to log a sale or make a note to restock after the rush.` : "Make a note to restock after the rush.";
        const inventoryRows = list => list.map(item => `<div class="inventory-row"><span class="item-art">${item.mark}</span><span><strong>${item.name}</strong><small>${money(item.price)} · ${item.sold} sold</small></span><span class="stock-count ${item.stock <= 2 ? "low" : ""}">${item.stock} left</span></div>`).join("");
        const bySold = [...items].sort((a, b) => b.sold - a.sold);
        const favorites = bySold.filter(item => item.sold > 0).slice(0, 3);
        const notPopular = bySold.filter(item => !favorites.includes(item)).slice(-3).reverse();
        qs("#homeInventory").innerHTML = inventoryRows(favorites);
        qs("#homeNotPopular").innerHTML = inventoryRows(notPopular);
        qs("#itemGrid").innerHTML = items.map(item => `<article class="sell-card"><div class="sell-art"><span>${item.mark}</span></div><strong>${item.name}</strong><small>${money(item.price)} · <span class="${item.stock <= 2 ? "stock-count low" : ""}">${item.stock} in stock</span></small><div class="sell-actions"><span style="font-size:10px;color:#92919e">${item.sold} sold today</span><button class="undo-sale" data-undo="${item.id}" aria-label="Remove one mistaken sale of ${item.name}" ${item.sold <= 0 ? "disabled" : ""}>−1 sold</button><button data-sell="${item.id}" ${item.stock <= 0 ? "disabled" : ""}>${item.stock <= 0 ? "Sold out" : "+1 sold"}</button></div></article>`).join("");
        qs("#postItem").innerHTML = items.map(item => `<option value="${item.id}">${item.name}</option>`).join("");
        updatePostPreview();
      }
      function updatePostPreview() {
        const item = items.find(entry => entry.id === qs("#postItem").value) || items[0];
        qs("#previewMark").textContent = item.mark;
        qs("#previewName").textContent = item.name;
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
          ? `Sell ${count} at ${money(midpoint)} to cover your ${money(booth)} table.`
          : "Add your booth fee to see how many sales cover your table.";
      }
      qsa("[data-open-app]").forEach(button => button.addEventListener("click", () => openApp()));
      qs("#badgeFlip").addEventListener("click", () => flipBadge());
      window.addEventListener("scroll", () => {
        if (!scrollRevealComplete && window.scrollY > 115) {
          scrollRevealComplete = true;
          flipBadge(true);
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
          showToast(`${item.name} · 1 sale removed`);
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
        showToast(`${item.name} · ${payment.toLowerCase()} sale added`);
      });
      qsa("[data-payment]").forEach(button => button.addEventListener("click", () => {
        payment = button.dataset.payment;
        qsa("[data-payment]").forEach(option => {
          const active = option === button;
          option.classList.toggle("active", active);
          option.setAttribute("aria-pressed", String(active));
        });
      }));
      ["materialCost", "workMinutes", "boothFee"].forEach(id => qs(`#${id}`).addEventListener("input", updatePrice));
      qs("#postItem").addEventListener("change", updatePostPreview);
      qsa("[data-template]").forEach(button => button.addEventListener("click", () => {
        activeTemplate = button.dataset.template;
        qsa("[data-template]").forEach(option => option.classList.toggle("active", option === button));
        updatePostPreview();
      }));
      qs("#captionButton").addEventListener("click", () => {
        const item = items.find(entry => entry.id === qs("#postItem").value) || items[0];
        qs("#captionOutput").textContent = `Meet your new favorite ${item.name.toLowerCase()}. Find me at Anime Fest, booth A-14! #artistalley #smallartist #animefest`;
      });
      qs("#downloadButton").addEventListener("click", () => {
        const item = items.find(entry => entry.id === qs("#postItem").value) || items[0];
        const colors = activeTemplate === "story" ? ["#c1b3ff", "#7bdcff"] : activeTemplate === "flyer" ? ["#ffb36b", "#a899ff"] : ["#ff9bdc", "#a899ff"];
        const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="1080" viewBox="0 0 1080 1080"><defs><linearGradient id="g" x2="1" y2="1"><stop stop-color="${colors[0]}"/><stop offset="1" stop-color="${colors[1]}"/></linearGradient></defs><rect width="1080" height="1080" rx="70" fill="url(#g)"/><text x="540" y="170" text-anchor="middle" font-family="Arial,sans-serif" font-size="38" font-weight="700" letter-spacing="8" fill="#191624">MYBLENX STICKERS</text><text x="540" y="590" text-anchor="middle" font-family="Arial,sans-serif" font-size="100" font-weight="700" letter-spacing="12" fill="#191624">${item.mark}</text><text x="540" y="760" text-anchor="middle" font-family="Arial,sans-serif" font-size="68" font-weight="700" fill="#191624">${item.name.replace(/[&<>"]/g, "")}</text><text x="540" y="840" text-anchor="middle" font-family="Arial,sans-serif" font-size="34" fill="#191624">Find your new favorite!</text></svg>`;
        const link = document.createElement("a");
        link.href = URL.createObjectURL(new Blob([svg], { type: "image/svg+xml" }));
        link.download = "pop-up-pass-post.svg";
        link.click();
        URL.revokeObjectURL(link.href);
        showToast("Your design is ready to save.");
      });
      qsa("[data-audience]").forEach(button => button.addEventListener("click", () => {
        const trends = {
          artist: ["A", "New Moment", "Try out a new set or collection. Fit your style and make your new fan favorites."],
          crafter: ["C", "Creative Detail", "From crochets to keychains, accessories make an easy, giftable collection."],
          food: ["F", "What’s in Season", "A pretty specialty beverage or unique themed snack could be the next new trend."],
          student: ["S", "Focus on the Trends", "What’s old is new. Nostalgia is back, but so is pop culture. Find your niche for a fun, low-cost next drop."]
        };
        qsa("[data-audience]").forEach(option => {
          const active = option === button;
          option.classList.toggle("active", active);
          option.setAttribute("aria-selected", String(active));
        });
        const [mark, title, copy] = trends[button.dataset.audience];
        qs("#audienceTrend").innerHTML = `<div class="trend-mark">${mark}</div><div><strong>${title}</strong><p>${copy}</p></div>`;
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
      render();
      updatePrice();
    })();
