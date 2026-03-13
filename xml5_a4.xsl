<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="html" encoding="UTF-8" indent="yes"/>

  <!-- ══════════════════════════
       ROOT TEMPLATE
  ══════════════════════════ -->
  <xsl:template match="/">
    <html lang="en">
      <head>
        <meta charset="UTF-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <title>The Murder of Roger Ackroyd</title>
        <link href="https://fonts.googleapis.com/css2?family=EB+Garamond:ital,wght@0,400;0,700;1,400;1,700&amp;display=swap" rel="stylesheet"/>
        <style>

          *, *::before, *::after {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
          }

          body {
            background: #aaaaaa;
            font-family: 'EB Garamond', Georgia, serif;
            padding: 40px 20px;
          }

          /* ══════════════════════════════════
             A4 PAGE
             A4 = 210mm x 297mm
             At 96dpi screen: 794px x 1123px
          ══════════════════════════════════ */
          .a4-page {
            background: #ffffff;
            width:  794px;          /* A4 width  at 96dpi */
            height: 1123px;         /* A4 height at 96dpi */
            margin: 0 auto 40px auto;
            box-shadow: 0 4px 28px rgba(0,0,0,0.20);
            overflow: hidden;       /* content that overflows goes to next page */
            position: relative;

            /* inner padding like real book margins */
            padding: 90px 80px 90px 80px;
          }

          /* ══════════════════════════════════
             CHAPTER OPENING PAGE  (Image 2)
          ══════════════════════════════════ */
          .chapter-opening {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: flex-start;
            padding-top: 120px;
            height: 100%;
          }

          .chapter-numeral {
            font-family: 'EB Garamond', Georgia, serif;
            font-size: 2.8rem;
            font-weight: 700;
            color: #111;
            margin-bottom: 50px;
            text-align: center;
          }

          .chapter-heading-title {
            font-family: 'EB Garamond', Georgia, serif;
            font-size: 1.2rem;
            font-weight: 700;
            color: #111;
            text-align: center;
            letter-spacing: 0.01em;
          }

          .big-letter {
            font-size: 1.2rem;
            font-weight: 700;
          }

          /* ══════════════════════════════════
             BODY TEXT PAGES  (Image 1)
             Uses CSS columns trick + page break
          ══════════════════════════════════ */
          .body-content {
            /* nothing special — paragraphs flow naturally */
          }

          /* normal paragraph */
          p.body-para {
            font-size: 1.02rem;
            line-height: 1.80;
            color: #111;
            margin-bottom: 0;
            text-align: justify;
            /* allow paragraph to break across pages */
            break-inside: auto;
          }

          /* indented paragraph */
          p.indent-para {
            font-size: 1.02rem;
            line-height: 1.80;
            color: #111;
            text-indent: 2em;
            margin-bottom: 0;
            text-align: justify;
            break-inside: auto;
          }

          /* inline italic */
          em {
            font-style: italic;
          }

          /* ══════════════════════════════════
             PRINT STYLES
             When user prints or saves as PDF,
             each .a4-page becomes exactly one page
          ══════════════════════════════════ */
          @media print {
            body {
              background: white;
              padding: 0;
              margin: 0;
            }

            .a4-page {
              width: 210mm;
              height: 297mm;
              margin: 0;
              padding: 25mm 20mm 25mm 20mm;
              box-shadow: none;
              page-break-after: always;
              break-after: page;
              overflow: hidden;
            }
          }

        </style>
      </head>
      <body>
        <xsl:apply-templates select="bodyMatter/chapter"/>
      </body>
    </html>
  </xsl:template>

  <!-- ══════════════════════════════════════════════
       CHAPTER TEMPLATE
       - Page 1: opening (numeral + heading)
       - Page 2+: body text split into A4 pages
  ══════════════════════════════════════════════ -->
  <xsl:template match="chapter">

    <!-- PAGE 1: Chapter opening (Image 2 style) -->
    <div class="a4-page">
      <div class="chapter-opening">
        <div class="chapter-numeral">
          <xsl:value-of select="title/titlelable"/>
        </div>
        <div class="chapter-heading-title">
          <xsl:apply-templates select="title/heading"/>
        </div>
      </div>
    </div>

    <!-- PAGE 2+: Body text pages (Image 1 style)
         JavaScript splits the content into A4-height pages automatically -->
    <div class="chapter-body-wrapper"
         data-chapter="{title/titlelable}">
      <xsl:apply-templates select="para | Para | indentedPara | indentPara"/>
    </div>

    <!-- Script runs after each chapter to paginate its body text -->
    <script>
      (function() {
        var PAGE_H = 1123;   /* A4 height in px at 96dpi          */
        var PAD_T  = 90;     /* top padding    (matches .a4-page)  */
        var PAD_B  = 90;     /* bottom padding (matches .a4-page)  */
        var CONTENT_H = PAGE_H - PAD_T - PAD_B;  /* 943px usable  */

        /* find the wrapper we just rendered */
        var wrappers = document.querySelectorAll('.chapter-body-wrapper');
        var wrapper  = wrappers[wrappers.length - 1];
        if (!wrapper) return;

        /* collect all paragraph elements */
        var paras = Array.from(wrapper.children);
        if (paras.length === 0) return;

        /* detach paragraphs from DOM temporarily */
        paras.forEach(function(p) { wrapper.removeChild(p); });

        /* build pages */
        var pages   = [];
        var current = createPage();
        var usedH   = 0;

        paras.forEach(function(p) {
          /* clone paragraph into an off-screen div to measure height */
          var probe = document.createElement('div');
          probe.style.cssText =
            'position:absolute;visibility:hidden;width:634px;' +
            'font-family:inherit;font-size:1.02rem;line-height:1.80;';
          probe.appendChild(p.cloneNode(true));
          document.body.appendChild(probe);
          var h = probe.offsetHeight;
          document.body.removeChild(probe);

          if (usedH + h > CONTENT_H &amp;&amp; usedH > 0) {
            /* current page is full — start a new one */
            pages.push(current);
            current = createPage();
            usedH   = 0;
          }

          current.querySelector('.body-content').appendChild(p);
          usedH += h;
        });

        /* push last page */
        if (current.querySelector('.body-content').children.length > 0) {
          pages.push(current);
        }

        /* replace wrapper with finished pages */
        pages.forEach(function(page) {
          wrapper.parentNode.insertBefore(page, wrapper);
        });
        wrapper.parentNode.removeChild(wrapper);

        function createPage() {
          var page = document.createElement('div');
          page.className = 'a4-page';
          var content = document.createElement('div');
          content.className = 'body-content';
          page.appendChild(content);
          return page;
        }
      })();
    </script>

  </xsl:template>

  <!-- ══════════════════════════
       HEADING TEMPLATES
  ══════════════════════════ -->
  <xsl:template match="heading">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="title-bigLetter">
    <span class="big-letter"><xsl:value-of select="."/></span>
  </xsl:template>

  <!-- ══════════════════════════
       PARAGRAPH TEMPLATES
  ══════════════════════════ -->
  <xsl:template match="para | Para">
    <p class="body-para">
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <xsl:template match="indentedPara | indentPara">
    <p class="indent-para">
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <!-- ══════════════════════════
       INLINE ITALIC
  ══════════════════════════ -->
  <xsl:template match="i">
    <em><xsl:apply-templates/></em>
  </xsl:template>

</xsl:stylesheet>
