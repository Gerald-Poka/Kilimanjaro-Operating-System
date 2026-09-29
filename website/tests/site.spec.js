import { test, expect } from "@playwright/test";

test("release status separates passed virtual tests from pending physical qualification", async ({
  page,
}) => {
  await page.goto("/downloads");
  await page
    .getByRole("link", { name: "Passed tests & remaining release gates" })
    .click();
  await expect(page).toHaveURL(/\/release-status$/);
  await expect(page).toHaveTitle("Kilimanjaro OS — Release status");
  await expect(page.locator("#passed-checks")).toContainText(
    "Secure Boot enabled",
  );
  await expect(page.locator("#release-gates article")).toHaveCount(6);
  await expect(page.locator("main")).toContainText(
    "No physical machine has been qualified yet",
  );
  await expect(
    page.getByRole("link", { name: "Browse the project on GitHub" }),
  ).toHaveAttribute(
    "href",
    "https://github.com/Gerald-Poka/Kilimanjaro-Operating-System",
  );
  await page.reload();
  await expect(page.locator("#safe-testing")).toContainText(
    "compatibility target, not a guarantee",
  );
});

test("relative type supports enlarged text and footer contrast is readable", async ({
  page,
}, info) => {
  await page.setViewportSize({ width: 720, height: 1000 });
  for (const route of [
    "/",
    "/why-kilimanjaro",
    "/explore",
    "/desktop",
    "/downloads",
    "/getting-started",
    "/about",
    "/documentation",
    "/legal",
    "/release-status",
  ]) {
    await page.goto(route);
    await page.addStyleTag({ content: "html { font-size: 200% !important; }" });
    await expect(page.locator(".footer p")).toHaveCSS("font-size", "32px");
    await expect(page.locator(".footer > span")).toHaveCSS("font-size", "28px");
    expect(
      await page.evaluate(
        () => document.documentElement.scrollWidth <= innerWidth,
      ),
      `enlarged text overflow on ${route}`,
    ).toBe(true);
  }
  await page.goto("/about");
  const ratios = await page.evaluate(() => {
    const luminance = (color) => {
      const rgb = color
        .match(/[\d.]+/g)
        .slice(0, 3)
        .map((value) => Number(value) / 255)
        .map((value) =>
          value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4,
        );
      return rgb[0] * 0.2126 + rgb[1] * 0.7152 + rgb[2] * 0.0722;
    };
    const background = luminance(
      getComputedStyle(document.body).backgroundColor,
    );
    return [
      ...document.querySelectorAll(".footer p, .footer > span, .footer > a"),
    ].map((element) => {
      const foreground = luminance(getComputedStyle(element).color);
      return (
        (Math.max(background, foreground) + 0.05) /
        (Math.min(background, foreground) + 0.05)
      );
    });
  });
  ratios.forEach((ratio) => expect(ratio).toBeGreaterThanOrEqual(4.5));
  await page
    .locator(".footer")
    .screenshot({ path: `test-results/${info.project.name}-footer.png` });
});

test("all pages use readable text sizes and reflow on narrow screens", async ({
  page,
}) => {
  const routes = [
    "/",
    "/why-kilimanjaro",
    "/explore",
    "/desktop",
    "/downloads",
    "/getting-started",
    "/about",
    "/documentation",
    "/legal",
    "/release-status",
  ];
  for (const width of [320, 768, 1440]) {
    await page.setViewportSize({ width, height: 1000 });
    for (const route of routes) {
      await page.goto(route);
      const smallText = await page.evaluate(() => {
        const walker = document.createTreeWalker(
          document.body,
          NodeFilter.SHOW_TEXT,
        );
        const failures = [];
        while (walker.nextNode()) {
          const node = walker.currentNode;
          const element = node.parentElement;
          if (
            !node.textContent.trim() ||
            !element ||
            element.closest("script, style, svg") ||
            !element.getClientRects().length
          )
            continue;
          const size = parseFloat(getComputedStyle(element).fontSize);
          if (size < 14)
            failures.push({ text: node.textContent.trim().slice(0, 80), size });
        }
        return failures;
      });
      expect(smallText, `${route} at ${width}px`).toEqual([]);
      expect(
        await page.evaluate(
          () => document.documentElement.scrollWidth <= innerWidth,
        ),
        `${route} overflow at ${width}px`,
      ).toBe(true);
      await expect(page.locator(".footer > span")).toHaveCSS(
        "font-size",
        "14px",
      );
      await expect(page.locator(".footer p")).toHaveCSS("font-size", "16px");
    }
  }
});

test("why page focuses on gaming, creation and daily tasks with working tool links", async ({
  page,
}) => {
  await page.goto("/why-kilimanjaro");
  await expect(page.locator(".benefit-card")).toHaveCount(3);
  await expect(page.locator(".benefit-gaming")).toContainText(
    "Optional Gaming Ready profile",
  );
  await expect(page.locator(".benefit-creation")).toContainText("OBS included");
  await expect(page.locator(".benefit-everyday")).toContainText(
    "Everyday essentials included",
  );
  await expect(
    page.getByText("Your bando matters.", { exact: true }),
  ).toHaveCount(0);
  for (const [label, category] of [
    ["Explore gaming tools", "Gaming"],
    ["Explore creator tools", "Creation"],
    ["Explore everyday tools", "Everyday"],
  ]) {
    await page.getByRole("link", { name: label }).click();
    await expect(page).toHaveURL(
      new RegExp("/explore\\?category=" + category + "$"),
    );
    await expect(
      page.getByRole("button", { name: category, exact: true }),
    ).toHaveAttribute("aria-pressed", "true");
    await page.goBack();
    await expect(page).toHaveURL(/\/why-kilimanjaro$/);
  }
});

test("author name opens the correct WhatsApp contact", async ({ page }) => {
  await page.goto("/about");
  const authorLinks = page.getByRole("link", {
    name: "Gerald Ndyamukama",
    exact: true,
  });
  await expect(authorLinks).toHaveCount(2);
  for (const link of await authorLinks.all()) {
    await expect(link).toHaveAttribute("href", "https://wa.me/255754318464");
  }
  // Verify the click destination without contacting WhatsApp during the test.
  await page.route("https://wa.me/255754318464", (route) =>
    route.fulfill({
      contentType: "text/plain",
      body: "WhatsApp test destination",
    }),
  );
  await authorLinks.first().click();
  await expect(page).toHaveURL("https://wa.me/255754318464");
});

test("automatic wallpaper rotation and pointer field stop when paused", async ({
  page,
}, info) => {
  test.skip(
    info.project.name === "mobile",
    "The pointer field is only for fine-pointer devices",
  );
  await page.goto("/");
  await expect
    .poll(() => page.locator(".scene-label strong").textContent(), {
      timeout: 14000,
    })
    .toBe("Kilimanjaro dawn");
  await page.mouse.move(1050, 380);
  await expect
    .poll(() =>
      page.locator("canvas").evaluate((canvas) => {
        const pixels = canvas
          .getContext("2d")
          .getImageData(0, 0, canvas.width, canvas.height).data;
        return pixels.some((value, index) => index % 4 === 3 && value > 0);
      }),
    )
    .toBe(true);
  await page.getByRole("button", { name: "Pause background motion" }).click();
  await expect
    .poll(() =>
      page.locator("canvas").evaluate((canvas) => {
        const pixels = canvas
          .getContext("2d")
          .getImageData(0, 0, canvas.width, canvas.height).data;
        return pixels.every((value, index) => index % 4 !== 3 || value === 0);
      }),
    )
    .toBe(true);
});

test("small screens and tablets do not overflow horizontally", async ({
  page,
}) => {
  for (const width of [320, 768, 1024]) {
    await page.setViewportSize({ width, height: 900 });
    await page.goto("/");
    expect(
      await page.evaluate(
        () => document.documentElement.scrollWidth <= window.innerWidth,
      ),
    ).toBe(true);
  }
});

test("home, navigation and responsive layout", async ({ page }, info) => {
  const errors = [];
  page.on("pageerror", (error) => errors.push(error.message));
  await page.goto("/");
  await expect(page.getByRole("heading", { level: 1 })).toContainText(
    "A new perspective",
  );
  await expect(page.locator(".hero-scene.active")).toHaveCSS(
    "background-image",
    /sunset\.webp/,
  );
  if (info.project.name === "mobile") {
    await page.getByRole("button", { name: "Open navigation" }).click();
    await page
      .getByRole("navigation")
      .getByRole("link", { name: "Explore", exact: true })
      .click();
    await expect(
      page.getByRole("button", { name: "Open navigation" }),
    ).toHaveAttribute("aria-expanded", "false");
  }
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= window.innerWidth,
    ),
  ).toBe(true);
  await page.getByRole("link", { name: "Kilimanjaro OS home" }).click();
  await page.locator("#home").scrollIntoViewIfNeeded();
  await page.locator("img").evaluateAll((images) =>
    images.forEach((image) => {
      image.loading = "eager";
    }),
  );
  await expect
    .poll(() =>
      page
        .locator("img")
        .evaluateAll((images) =>
          images.every((image) => image.complete && image.naturalWidth > 0),
        ),
    )
    .toBe(true);
  await page.screenshot({
    path: `test-results/${info.project.name}-home.png`,
    fullPage: true,
  });
  await page.screenshot({ path: `test-results/${info.project.name}-hero.png` });
  expect(errors).toEqual([]);
});

test("wallpaper controls, application filters and FAQ work", async ({
  page,
}) => {
  await page.goto("/");
  await page
    .getByRole("button", { name: "Show Blue hour", exact: true })
    .click();
  await expect(page.locator(".scene-label strong")).toHaveText("Blue hour");
  await page.getByRole("button", { name: "Pause background motion" }).click();
  await expect(
    page.getByRole("button", { name: "Resume background motion" }),
  ).toHaveAttribute("aria-pressed", "true");
  await page.goto("/desktop");
  await page
    .getByRole("group", { name: "Explore desktop wallpapers" })
    .getByRole("button", { name: "Uhuru glacier" })
    .click();
  await expect(page.locator(".desktop-preview > img")).toHaveAttribute(
    "src",
    "/wallpapers/glacier.webp",
  );
  await page.goto("/explore");
  await page.getByRole("button", { name: "Gaming", exact: true }).click();
  await expect(page.locator(".app-card")).toHaveCount(2);
  await expect(page.locator(".app-card").first()).toContainText(
    "Optional profile",
  );
  await page
    .getByRole("textbox", { name: "Search applications" })
    .fill("LibreOffice");
  await expect(page.locator(".app-card")).toHaveCount(1);
  await page
    .getByRole("textbox", { name: "Search applications" })
    .fill("not-existing-xyz");
  await expect(page.locator(".empty-state")).toBeVisible();
  await page.goto("/getting-started");
  await page
    .locator("summary")
    .filter({ hasText: "Is this ready for my everyday computer?" })
    .click();
  await expect(page.locator("details[open]")).toContainText("Not yet.");
});

test("reduced motion is respected and unreleased downloads are honest", async ({
  page,
}) => {
  await page.emulateMedia({ reducedMotion: "reduce" });
  await page.route("**/release.json", (route) =>
    route.fulfill({ status: 404, body: "{}" }),
  );
  await page.goto("/");
  await expect(
    page.getByRole("button", { name: "Resume background motion" }),
  ).toBeDisabled();

  await page.getByRole("button", { name: "Show Kilimanjaro dawn" }).click();
  await expect(page.locator(".scene-label strong")).toHaveText(
    "Kilimanjaro dawn",
  );
  await page.goto("/downloads");
  await expect(
    page.getByRole("button", { name: "Public download not published yet" }),
  ).toBeDisabled();
  await expect(page.locator(".release-warning")).toContainText(
    "GPG signing is pending",
  );
});

test("staged release has downloadable ISO and checksum without reading ISO into memory", async ({
  page,
  request,
}) => {
  await page.goto("/downloads");
  const response = await request.get("/release.json");
  test.skip(!response.ok(), "No release staged in this checkout");
  const release = await response.json();
  await expect(
    page.getByRole("link", { name: "Download development ISO" }),
  ).toHaveAttribute("href", `/releases/${release.file}`);
  const checksum = await request.get("/releases/SHA256SUMS");
  expect(await checksum.text()).toContain(release.sha256);
  const iso = await request.head(`/releases/${release.file}`);
  expect(iso.ok()).toBe(true);
  expect(Number(iso.headers()["content-length"])).toBeGreaterThan(1000000000);
});

test("each navigation tab opens a separate page and supports back/forward", async ({
  page,
}, info) => {
  await page.goto("/");
  const links = [
    ["Why Kilimanjaro", "/why-kilimanjaro", "Play. Create."],
    ["Explore", "/explore", "Less setup"],
    ["Desktop", "/desktop", "A place to"],
    ["Getting started", "/getting-started", "From download"],
    ["Documentation", "/documentation", "Your first steps"],
    ["About", "/about", "Built with purpose"],
    ["Get Kilimanjaro", "/downloads", "Take the"],
  ];
  for (const [label, route, heading] of links) {
    if (info.project.name === "mobile")
      await page.getByRole("button", { name: "Open navigation" }).click();
    await page
      .getByRole("navigation", { name: "Main navigation" })
      .getByRole("link", { name: label, exact: true })
      .click();
    await expect(page).toHaveURL(new RegExp(route + "$"));
    await expect(page.getByRole("heading", { level: 1 })).toContainText(
      heading,
    );
    await expect(
      page.locator(`#navigation a[href="${route}"]`),
    ).toHaveAttribute("aria-current", "page");
    await expect(page.locator(".hero")).toHaveCount(0);
    expect(await page.evaluate(() => window.scrollY)).toBe(0);
    await page.reload();
    await expect(page.getByRole("heading", { level: 1 })).toContainText(
      heading,
    );
    await expect(page).toHaveTitle(/Kilimanjaro OS/);
    await page.screenshot({
      path: "test-results/" + info.project.name + route + ".png",
      fullPage: true,
    });
  }
  await page.goBack();
  await expect(page).toHaveURL(/\/about$/);
  await page.goForward();
  await expect(page).toHaveURL(/\/downloads$/);
  await page.getByRole("link", { name: "Read the testing guide" }).click();
  await expect(page).toHaveURL(/\/getting-started$/);
  await page.goto("/missing-page");
  await expect(page.getByRole("heading", { level: 1 })).toContainText(
    "This page isn’t here",
  );
  await page.getByRole("link", { name: "Back to home" }).click();
  await expect(page).toHaveURL("http://127.0.0.1:5173/");
});

test("documentation sections, safety guidance and legal page work", async ({
  page,
  request,
}, info) => {
  const errors = [];
  page.on("pageerror", (error) => errors.push(error.message));
  await page.goto("/documentation");
  await page.screenshot({
    path: `test-results/${info.project.name}/documentation-top.png`,
  });
  await expect(page.locator(".guide-section")).toHaveCount(7);
  await expect(page.locator("main")).toContainText(
    "Release GPG signing is pending",
  );
  await expect(page.locator("#installation")).toContainText(
    "Erase disk deletes every existing partition",
  );
  await expect(page.locator("#before-installing")).toContainText(
    "qualification remain pending",
  );
  const contents = page.getByRole("navigation", {
    name: "Documentation contents",
  });
  for (const link of await contents.getByRole("link").all()) {
    const target = await link.getAttribute("href");
    await expect(page.locator(target)).toHaveCount(1);
    await link.click();
    await expect(page).toHaveURL(new RegExp(target + "$"));
    await expect(
      page.locator(target).getByRole("heading", { level: 2 }),
    ).toBeInViewport();
  }
  await page.goto("/documentation");
  await page.screenshot({
    path: `test-results/${info.project.name}/documentation.png`,
    fullPage: true,
  });
  await page
    .getByRole("navigation", { name: "Resources" })
    .getByRole("link", { name: "Legal overview" })
    .click();
  await expect(page).toHaveURL(/\/legal$/);
  await expect(page.getByRole("heading", { level: 1 })).toContainText(
    "Legal overview",
  );
  await expect(page.locator(".legal-cards article")).toHaveCount(4);
  await expect(page.locator("main")).toContainText("Independent from Debian");
  await expect(page.locator("main")).toContainText("GPL-3.0-only");
  await expect(
    page.getByRole("link", { name: "complete GPL-3.0 license" }),
  ).toHaveAttribute("href", "/LICENSE.txt");
  const license = await request.get("/LICENSE.txt");
  expect(license.ok()).toBe(true);
  expect(await license.text()).toContain("Version 3, 29 June 2007");
  const scope = await request.get("/licensing.txt");
  expect(await scope.text()).toContain("GPL-3.0-only");
  await expect(page.locator("main")).toContainText(
    "no professional support contract",
  );
  await expect(page.locator("main")).not.toContainText("RPMFusion");
  await expect(
    page.getByRole("link", { name: "Debian’s package-license guidance" }),
  ).toHaveAttribute("href", "https://www.debian.org/legal/disclaimer/");
  await page.reload();
  await expect(page).toHaveTitle("Kilimanjaro OS — Legal overview");
  await page.screenshot({
    path: `test-results/${info.project.name}/legal-top.png`,
  });
  await page.screenshot({
    path: `test-results/${info.project.name}/legal.png`,
    fullPage: true,
  });
  await page
    .getByRole("link", { name: "documentation and current limitations" })
    .click();
  await expect(page).toHaveURL(/\/documentation$/);
  expect(errors).toEqual([]);
});
