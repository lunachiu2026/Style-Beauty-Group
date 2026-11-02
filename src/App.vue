<script setup>
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from 'vue'
import inquiryWizardHtml from '../prototypes/inquiry-wizard.html?raw'

const appBasePath = import.meta.env.BASE_URL.replace(/\/$/, '')
const appPathname = () => {
  const pathname = window.location.pathname
  if (appBasePath && pathname.startsWith(appBasePath)) return pathname.slice(appBasePath.length) || '/'
  return pathname
}
const withAppBase = (pathname) => `${appBasePath}${pathname === '/' ? '/' : pathname}`
const assetPath = (path) => path?.startsWith('/') ? `${appBasePath}${path}` : path

const menuOpen = ref(false)
const aboutMenuOpen = ref(false)
const makeupMenuOpen = ref(false)
const searchOpen = ref(false)
const searchQuery = ref('')
const selectedCatalogImage = ref('')
const recommendationsOpen = ref(false)
const solutionIndex = ref(0)
const solutionTrackIndex = ref(0)
const solutionTransitionDuration = ref(700)
const solutionsPaused = ref(false)
const solutionTransitionPages = ref(null)
const solutionWrapToFirst = ref(false)
const solutionPageSize = 4
const inspirationIndex = ref(0)
const makeupSolutionPage = ref(0)
const sunCareSolutionIndex = ref(0)
const makeupInspirationFocus = ref(0)
const makeupInsightFocus = ref(0)
const language = ref(localStorage.getItem('style-language') || 'zh')
const expandedMakeupCategory = ref('')
const catalogVisibleCount = ref(8)
const catalogLoadTrigger = ref(null)
const cartOpen = ref(false)
const cartItems = ref(JSON.parse(localStorage.getItem('style-cart') || '[]'))
const contactMode = ref('email')
const inquiryFrame = ref(null)
const inquiryFrameHeight = ref(760)
const beautyHubTab = ref('hub-solutions')
const directCaptcha = ref(String(Math.floor(100000 + Math.random() * 900000)))
const directCaptchaError = ref('')
const directForm = ref({ name: '', email: '', company: '', country: '', whatsapp: '', message: '', captcha: '' })
const contactStep = ref(1)
const contactForm = ref({
  service: '',
  categories: [],
  timeline: '',
  quantity: '',
  message: '',
  name: '',
  company: '',
  email: '',
  phone: '',
})

const contactOptions = computed(() => language.value === 'zh' ? {
  services: [
    ['oem', 'OEM 代工製造', '已有明確配方或產品規格'],
    ['odm', 'ODM 客製開發', '從概念、配方到量產共同開發'],
    ['private-label', '自有品牌方案', '快速建立品牌與產品系列'],
    ['unsure', '還不確定', '由專人協助釐清合適方案'],
  ],
  categories: [['makeup', '彩妝'], ['skincare', '保養品'], ['sun-care', '防曬'], ['mens-care', '男士保養'], ['other', '其他']],
  timelines: [['3-months', '3 個月內'], ['3-6-months', '3–6 個月'], ['6-12-months', '6–12 個月'], ['planning', '尚在規劃']],
} : {
  services: [
    ['oem', 'OEM Manufacturing', 'I already have a formula or product specification'],
    ['odm', 'ODM Development', 'Develop the concept, formula and production together'],
    ['private-label', 'Private Label', 'Launch a brand and product line efficiently'],
    ['unsure', 'Not sure yet', 'Let our team recommend the right path'],
  ],
  categories: [['makeup', 'Makeup'], ['skincare', 'Skincare'], ['sun-care', 'Sun Care'], ['mens-care', "Men's Care"], ['other', 'Other']],
  timelines: [['3-months', 'Within 3 months'], ['3-6-months', '3–6 months'], ['6-12-months', '6–12 months'], ['planning', 'Still planning']],
})

const contactStepValid = computed(() => {
  if (contactStep.value === 1) return Boolean(contactForm.value.service)
  if (contactStep.value === 2) return contactForm.value.categories.length > 0
  if (contactStep.value === 3) return Boolean(contactForm.value.timeline && contactForm.value.message.trim())
  return Boolean(contactForm.value.name.trim() && /\S+@\S+\.\S+/.test(contactForm.value.email))
})

const contactEmailHref = computed(() => {
  const optionLabel = (options, value) => options.find(([key]) => key === value)?.[1] || value
  const categoryLabels = contactForm.value.categories.map(value => optionLabel(contactOptions.value.categories, value)).join('、')
  const subject = language.value === 'zh' ? `產品合作詢問｜${contactForm.value.company || contactForm.value.name}` : `Product inquiry | ${contactForm.value.company || contactForm.value.name}`
  const body = language.value === 'zh'
    ? `合作需求：${optionLabel(contactOptions.value.services, contactForm.value.service)}\n產品類別：${categoryLabels}\n預計時程：${optionLabel(contactOptions.value.timelines, contactForm.value.timeline)}\n預估數量：${contactForm.value.quantity || '未提供'}\n\n專案說明：\n${contactForm.value.message}\n\n聯絡人：${contactForm.value.name}\n公司／品牌：${contactForm.value.company || '未提供'}\nEmail：${contactForm.value.email}\n電話：${contactForm.value.phone || '未提供'}`
    : `Service: ${optionLabel(contactOptions.value.services, contactForm.value.service)}\nCategories: ${categoryLabels}\nTimeline: ${optionLabel(contactOptions.value.timelines, contactForm.value.timeline)}\nEstimated quantity: ${contactForm.value.quantity || 'Not provided'}\n\nProject details:\n${contactForm.value.message}\n\nName: ${contactForm.value.name}\nCompany / brand: ${contactForm.value.company || 'Not provided'}\nEmail: ${contactForm.value.email}\nPhone: ${contactForm.value.phone || 'Not provided'}`
  return `mailto:style-diana@stylebeautygroup.com?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`
})

const sendDirectEmail = () => {
  if (directForm.value.captcha.trim() !== directCaptcha.value) {
    directCaptchaError.value = language.value === 'zh' ? '驗證碼不正確，請重新輸入。' : 'The captcha code is incorrect.'
    return
  }

  directCaptchaError.value = ''
  const subject = language.value === 'zh' ? `網站聯絡｜${directForm.value.name}` : `Website inquiry | ${directForm.value.name}`
  const body = language.value === 'zh'
    ? `姓名：${directForm.value.name}\nEmail：${directForm.value.email}\n公司名稱：${directForm.value.company || '未提供'}\n國家：${directForm.value.country || '未提供'}\nWhatsApp：${directForm.value.whatsapp || '未提供'}\n\n訊息：\n${directForm.value.message}`
    : `Name: ${directForm.value.name}\nEmail: ${directForm.value.email}\nCompany: ${directForm.value.company || 'Not provided'}\nCountry: ${directForm.value.country || 'Not provided'}\nWhatsApp: ${directForm.value.whatsapp || 'Not provided'}\n\nMessage:\n${directForm.value.message}`
  window.location.href = `mailto:style-diana@stylebeautygroup.com?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`
}

const pages = {
  'beauty-hub': {},
  about: {
    eyebrow: 'ABOUT STYLE BEAUTY GROUP',
    title: 'Your Product Vision, Made Possible.',
    description: 'A trusted beauty manufacturing partner, from the first idea to a finished product ready for market.',
    image: 'photo-1556229010-6c3f2c9ca5f8',
    heading: 'More than manufacturing',
    body: 'We bring formulation, product development, packaging and manufacturing together in one collaborative process. Our team works alongside your brand to turn a clear vision into a product customers will love.',
    features: ['40+ years of beauty expertise', 'Customized OEM & ODM development', 'Quality-minded production in Taiwan'],
  },
  makeup: {
    eyebrow: 'MAKEUP DEVELOPMENT',
    title: 'Color, Texture, Performance.',
    description: 'Create makeup with the shades, feel and staying power your customers expect.',
    image: 'photo-1522335789203-aabd1fc54bc9',
    heading: 'Makeup made for your brand',
    body: 'From complexion and lip products to color cosmetics, we help develop formulas and finishes that align with your brand identity, target audience and market goals.',
    features: ['Custom shades and textures', 'Wear and performance testing', 'Packaging and component sourcing'],
  },
  'sun-care': {
    eyebrow: 'SUN CARE DEVELOPMENT',
    title: 'Everyday Protection, Thoughtfully Made.',
    description: 'Develop sun care products that fit naturally into your customers’ routines.',
    image: 'photo-1608248543803-ba4f8c70ae0b',
    heading: 'Protection with a better feel',
    body: 'Explore sensory profiles, formats and packaging for your sun care range, with product development shaped around your brief and intended markets.',
    features: ['Daily-use product formats', 'Texture and sensory customization', 'Packaging support from concept to production'],
  },
  skincare: {
    eyebrow: 'SKINCARE DEVELOPMENT',
    title: 'Skincare, From Concept to Creation.',
    description: 'Build a skincare range with considered formulas, textures and packaging.',
    image: 'photo-1611930022073-b7a4ba5fcccd',
    heading: 'A complete skincare partner',
    body: 'We support your product journey from concept and formulation through testing, packaging coordination and manufacturing, keeping your brand goals at the center.',
    features: ['Formula and texture development', 'Private label and ODM options', 'Packaging coordination and production'],
  },
  'mens-care': {
    eyebrow: "MEN'S CARE DEVELOPMENT",
    title: 'Modern Care, Built Around Your Brand.',
    description: 'Develop practical, high-quality grooming products for the modern consumer.',
    image: 'photo-1620916566398-39f1143ab7be',
    heading: 'A fresh approach to grooming',
    body: 'From daily skincare to grooming essentials, we help shape a cohesive product range with the right formulation, user experience and presentation.',
    features: ['Flexible product concepts', 'Distinctive textures and formats', 'End-to-end OEM/ODM support'],
  },
  video: {
    eyebrow: 'OUR APPROACH',
    title: 'More Than a Manufacturer, A True Partner.',
    description: 'See how our team brings formulation expertise, packaging and production together for your next beauty project.',
    image: 'photo-1526778548025-fa2f459cd5c1',
    heading: 'From first conversation to finished product',
    body: 'Our process is built around collaboration. We learn about your idea, align on the product brief, and guide development through the decisions that bring it to life.',
    features: ['Share your product brief', 'Explore formula and packaging options', 'Develop and manufacture with one partner'],
  },
  contact: {
    eyebrow: 'CONTACT STYLE BEAUTY GROUP',
    title: 'Let’s Start Your Project.',
    description: 'Tell us what you are building. Our team will be in touch to discuss the right next steps.',
    image: 'photo-1556228578-0d85b1a4d571',
    heading: 'Talk with our team',
    body: 'Share your product idea, category, target market and estimated timeline. We will help you understand the development options for your project.',
    features: ['Email: style-diana@stylebeautygroup.com', 'Tel: +886-4-23370043', 'OEM, ODM and private label inquiries welcome'],
  },
}
const getPageKey = () => appPathname().split('/').filter(Boolean).at(-1) || 'home'
const currentPageKey = ref(getPageKey())
const currentPage = computed(() => {
  currentPageKey.value
  return appPathname().startsWith('/makeup') ? pages.makeup : pages[currentPageKey.value]
})
const pageTranslations = {
  about: ['關於 Style Beauty Group', '讓你的產品想法成真。', '從第一個構想到準備上市的產品，成為值得信賴的美妝製造夥伴。', '不只是製造', '我們整合配方、產品開發、包裝與製造流程，與品牌並肩合作，將清晰的願景化為消費者喜愛的產品。', ['累積超過 40 年美妝專業', '客製化 OEM 與 ODM 開發', '台灣製造，重視品質']],
  makeup: ['彩妝產品開發', '色彩、質地與表現力。', '打造符合消費者期待的色彩、觸感與持妝表現。', '為你的品牌打造彩妝', '從底妝、唇彩到各式彩妝品項，我們依品牌定位、目標客群與市場需求，協助開發合適的配方與妝效。', ['客製色彩與質地', '妝效與持妝測試', '包裝與容器採購支援']],
  'sun-care': ['防曬產品開發', '讓日常防護，細緻而自然。', '開發能自然融入消費者日常保養的防曬產品。', '打造舒適的防護體驗', '依據產品需求與目標市場，探索防曬系列的感官質地、產品形式與包裝選擇。', ['適合日常使用的產品形式', '客製質地與使用感受', '從概念到量產的包裝支援']],
  skincare: ['保養品開發', '從概念，走向完整保養系列。', '以細緻配方、質地與包裝，建立你的保養品系列。', '完整的保養品合作夥伴', '從產品概念、配方開發與測試，到包裝協調與製造，我們一路陪伴你的產品開發旅程。', ['配方與質地開發', '自有品牌與 ODM 選項', '包裝協調與產品製造']],
  'mens-care': ['男士保養品開發', '為你的品牌打造現代男士保養。', '開發實用且高品質的理容產品，回應現代消費者需求。', '重新思考日常理容', '從日常保養到理容必備品，協助你建立配方、使用體驗與品牌呈現一致的產品系列。', ['彈性的產品概念', '獨特質地與產品形式', '完整 OEM / ODM 支援']],
  video: ['我們的合作方式', '不只是製造商，更是你的夥伴。', '了解我們如何整合配方專業、包裝與生產，陪伴你的下一個美妝專案。', '從第一次對談，到產品完成', '我們重視每一次合作，從理解你的想法、確認產品需求，到陪你完成每個開發決策，讓構想一步步實現。', ['分享你的產品需求', '探索配方與包裝選項', '由同一個合作夥伴開發與製造']],
  contact: ['聯絡 Style Beauty Group', '一起啟動你的產品計畫。', '告訴我們你的構想，團隊將與你聯繫並討論下一步。', '與我們的團隊聊聊', '請分享產品想法、品類、目標市場與預計時程，我們將協助你了解適合的開發方式。', ['Email：style-diana@stylebeautygroup.com', '電話：+886-4-23370043', '歡迎洽詢 OEM、ODM 與自有品牌合作']],
}
const displayPage = computed(() => {
  if (!currentPage.value) return null
  if (language.value === 'en') return currentPage.value
  const [eyebrow, title, description, heading, body, features] = pageTranslations[currentPageKey.value]
  return { ...currentPage.value, eyebrow, title, description, heading, body, features }
})
const copy = computed(() => language.value === 'zh' ? {
  nav: ['首頁', '關於我們', '彩妝', '防曬', '保養品', '男士保養', '品牌故事', '聯絡我們'],
  search: '搜尋 Style Beauty Group', searchPlaceholder: '輸入關鍵字...',
  heroEyebrow: 'OEM　|　ODM　|　自有品牌', heroTitle: '美妝配方專家，\n成就品牌未來。', heroDescription: '從配方研發、客製化產品開發與包裝設計，到完整製造服務，陪伴你的品牌打造美妝產品。', heroMakeup: '探索彩妝', heroSkincare: '探索保養品',
  aboutEyebrow: '關於 STYLE BEAUTY GROUP', aboutTitle: '從你的想法，\n到消費者的心頭好。', aboutBody: 'Explore a wide range of innovative formulation textures, an endless spectrum of vibrant colors, and customized packaging designs to bring your beauty product ideas to life. STYLE BEAUTY GROUP is a leading OEM, ODM, and private label makeup manufacturer based in Taiwan, specializing in high-quality solutions for global beauty brands. As an experienced makeup manufacturer and innovative makeup factory, we provide customized product development and manufacturing services tailored to your brand’s needs. From concept to creation, our full-service OEM makeup and private label manufacturing solutions support your journey from product development to production, helping you build a distinctive brand and stay competitive in the beauty market.', aboutLink: '認識我們',
  whyEyebrow: '為什麼選擇 STYLE', whyTitle: '為什麼選擇我們？', whySubtitle: '值得信賴的美妝製造合作夥伴', featureExperience: '豐富經驗', featureCustom: '客製 OEM 與 ODM 方案', featureGlobal: '服務全球品牌', featureQuality: '認證與彈性 MOQ', featureGmp: '品質管理系統', feature1: '配方、開發與製造的專業經驗。', feature2: '從概念、配方到包裝與生產。', feature3: '以穩定品質建立長期合作關係。', feature4: '為不同階段的品牌提供彈性支援。', feature5: '以可靠流程把關每批產品品質。',
  approach: '我們的合作方式', partnerTitle: '不只是製造商，\n更是你的合作夥伴。', partnerBody1: '整合配方專業、產品開發、包裝方案與製造能力，提供完整的 OEM、ODM 與自有品牌服務。', partnerBody2: '我們不只製造產品，也期望成為品牌長期成長的夥伴，從概念實現到拓展在地與全球市場。', turnkey: '一站式解決方案', productsEyebrow: '產品品類', productsTitle: '彩妝與保養品', productsSubtitle: '從色彩妝效到日常保養，為品牌打造完整的美妝產品系列。', viewProducts: '瀏覽所有產品',
  solutionsEyebrow: '為你的品牌量身打造', solutionsTitle: '符合品牌需求的產品方案', solutionsSubtitle: '依照品牌定位與市場需求，探索適合的產品方向與配方靈感。', viewSolutions: '瀏覽所有方案', inspirationEyebrow: '美妝靈感與趨勢', inspirationTitle: '一起創造美妝新可能', viewInspiration: '瀏覽所有靈感', learnMore: '了解更多', exploreTrend: '探索趨勢', faqEyebrow: '專案支援', faqTitle: '常見問題', faqSubtitle: '有任何疑問嗎？歡迎與我們聯繫。',
  footerEyebrow: '讓下一個好產品從這裡開始', footerTitle: '啟動你的產品計畫', footerBody: '一起打造消費者喜愛的產品。', contactUs: '聯絡我們', backTop: '回到頂端', discuss: '洽談產品計畫', related: '探索其他品類',
} : {
  nav: ['HOME', 'ABOUT', 'MAKEUP', 'SUN CARE', 'SKINCARE', "MEN'S CARE", 'VIDEO', 'CONTACT'],
  search: 'Search Style Beauty Group', searchPlaceholder: 'Enter keywords...', heroEyebrow: 'OEM　|　ODM　|　PRIVATE LABEL', heroTitle: "Cosmetic Formula Experts.\nHelping You Build Your Brand's Future.", heroDescription: 'Your OEM/ODM manufacturing partner for innovative skincare, makeup, and personal care products. From concept and formulation to packaging and production, we help you create a distinctive brand and stay competitive in the beauty market.', heroMakeup: 'EXPLORE MAKEUP', heroSkincare: 'EXPLORE SKINCARE',
  aboutEyebrow: 'ABOUT STYLE BEAUTY GROUP', aboutTitle: 'From your idea\nto their new favorite.', aboutBody: 'Explore a wide range of innovative formulation textures, an endless spectrum of vibrant colors, and customized packaging designs to bring your beauty product ideas to life. STYLE BEAUTY GROUP is a leading OEM, ODM, and private label makeup manufacturer based in Taiwan, specializing in high-quality solutions for global beauty brands. As an experienced makeup manufacturer and innovative makeup factory, we provide customized product development and manufacturing services tailored to your brand’s needs. From concept to creation, our full-service OEM makeup and private label manufacturing solutions support your journey from product development to production, helping you build a distinctive brand and stay competitive in the beauty market.', aboutLink: 'ABOUT US',
  whyEyebrow: 'WHY STYLE', whyTitle: 'Why choose us?', whySubtitle: 'Your trusted cosmetics manufacturing partner', featureExperience: '40+ Years of Experience', featureCustom: 'Customized OEM & ODM Solutions', featureGlobal: 'Trusted by 100+ Brands Worldwide', featureQuality: 'Certified Solutions & Flexible MOQ', featureGmp: 'ISO 22716:2007 (GMP)', feature1: 'Professional expertise in formulation, development and manufacturing.', feature2: 'From concept and formulation to packaging and production.', feature3: 'Building successful global partnerships with care and consistency.', feature4: 'Quality systems and flexible support for brands at every stage.', feature5: 'Reliable quality assurance from the first batch to the next.',
  approach: 'OUR APPROACH', partnerTitle: 'More Than a Manufacturer,\nA True Partner', partnerBody1: 'We combine formulation expertise, product development, packaging solutions and manufacturing capabilities to provide comprehensive OEM/ODM and private label support.', partnerBody2: "Our goal is not just to make products, but to be a long-term partner in your brand's growth, from concept to creation and from local markets to global opportunities.", turnkey: 'TURNKEY SOLUTION', productsEyebrow: 'OUR PRODUCTS', productsTitle: 'Makeup & Skincare', productsSubtitle: 'Explore color, texture, and skincare concepts tailored to your brand.', viewProducts: 'VIEW ALL PRODUCTS',
  solutionsEyebrow: 'TAILORED FOR YOUR BRAND', solutionsTitle: "What your brand's needs?", solutionsSubtitle: 'Explore product directions and formulation ideas shaped around your brand and market.', viewSolutions: 'VIEW ALL SOLUTIONS', inspirationEyebrow: 'BEAUTY INSPIRATION / TRENDS', inspirationTitle: "Creating What's Next", viewInspiration: 'VIEW ALL INSPIRATION', learnMore: 'Learn more', exploreTrend: 'Explore trend', faqEyebrow: 'SUPPORT FOR YOUR PROJECT', faqTitle: 'Frequently Asked Questions', faqSubtitle: 'Have a question? Our team is ready to help.',
  footerEyebrow: 'YOUR NEXT GREAT PRODUCT STARTS HERE', footerTitle: 'START YOUR PROJECT', footerBody: "Let's create something your customers will love.", contactUs: 'CONTACT US', backTop: 'BACK TO TOP', discuss: 'DISCUSS YOUR PROJECT', related: 'EXPLORE OTHER CATEGORIES',
})

const setLanguage = (event) => {
  language.value = event.target.value
  localStorage.setItem('style-language', language.value)
  document.documentElement.lang = language.value === 'zh' ? 'zh-Hant' : 'en'
}
document.documentElement.lang = language.value === 'zh' ? 'zh-Hant' : 'en'

const navigateTo = (url) => {
  const pathname = appBasePath && url.pathname.startsWith(appBasePath) ? url.pathname.slice(appBasePath.length) || '/' : url.pathname
  const nextPageKey = pathname.split('/').filter(Boolean).at(-1) || 'home'
  const isMakeupPath = pathname === '/makeup' || pathname.startsWith('/makeup/')
  if (nextPageKey !== 'home' && !pages[nextPageKey] && !isMakeupPath) return

  window.history.pushState({}, '', withAppBase(pathname))
  currentPageKey.value = nextPageKey
  catalogVisibleCount.value = 8
  menuOpen.value = false
  aboutMenuOpen.value = false
  makeupMenuOpen.value = false
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

const handleInternalNavigation = (event) => {
  const link = event.target.closest?.('a')
  if (!link || link.target || link.hasAttribute('download')) return

  const url = new URL(link.href, window.location.href)
  if (url.origin !== window.location.origin || url.hash) return
  const pathname = appBasePath && url.pathname.startsWith(appBasePath) ? url.pathname.slice(appBasePath.length) || '/' : url.pathname
  if (pathname === appPathname()) {
    event.preventDefault()
    window.scrollTo({ top: 0, behavior: 'smooth' })
    return
  }

  const pageKey = pathname.split('/').filter(Boolean).at(-1) || 'home'
  const isMakeupPath = pathname === '/makeup' || pathname.startsWith('/makeup/')
  if (pageKey !== 'home' && !pages[pageKey] && !isMakeupPath) return

  event.preventDefault()
  navigateTo(url)
}

window.addEventListener('popstate', () => {
  currentPageKey.value = getPageKey()
  catalogVisibleCount.value = 8
  menuOpen.value = false
  window.scrollTo({ top: 0, behavior: 'smooth' })
})

const products = [
  { name: 'Makeup', zhName: '彩妝', category: 'COLOR, TEXTURE, PERFORMANCE', zhCategory: '色彩、質地與妝效', description: 'Color, texture, and performance solutions to bring your beauty brand to life.', zhDescription: '以色彩、質地與妝效，打造貼近品牌定位的美妝產品。', href: '/makeup', image: '/banner%20p%20.png' },
  { name: 'Sun Care', zhName: '防曬', category: 'DAILY PROTECTION', zhCategory: '日常防護', description: 'Thoughtful sun care formulas made for everyday routines.', zhDescription: '為日常保養打造兼具舒適質地與防護需求的產品。', href: '/sun-care', image: 'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&w=1800&q=85' },
  { name: 'Skincare', zhName: '保養品', category: 'SKINCARE INNOVATION', zhCategory: '保養創新', description: 'Considered formulas and textures for your next skincare collection.', zhDescription: '以細緻配方與使用質地，開發專屬於品牌的保養系列。', href: '/skincare', image: 'https://images.unsplash.com/photo-1601049541289-9b1b7bbbfe19?auto=format&fit=crop&w=1800&q=85' },
  { name: "Men's Care", zhName: '男士保養', category: 'MODERN GROOMING', zhCategory: '現代理容', description: 'Modern grooming essentials developed around your brand.', zhDescription: '依品牌特色開發現代男士理容與保養產品。', href: '/mens-care', image: 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?auto=format&fit=crop&w=1800&q=85' },
]

const makeupCategories = [
  {
    slug: 'face',
    name: 'Face',
    zhName: '臉部',
    detail: 'Foundation · Concealer · Powder · Blush',
    zhDetail: '粉底 · 遮瑕 · 蜜粉 · 腮紅',
    items: ['Liquid Foundation', 'Serum Foundation', 'Cream Foundation', 'Stick Foundation', 'Cushion Foundation', 'Powder Foundation', 'Tinted Moisturizer', 'BB Cream', 'CC Cream', 'Liquid Concealer', 'Cream Concealer', 'Color Corrector', 'Pressed Powder', 'Loose Powder', 'Setting Powder', 'Powder Blush', 'Cream Blush', 'Liquid Blush', 'Highlighter', 'Contour'],
    zhItems: ['粉底液', '精華粉底', '粉霜', '粉底棒', '氣墊粉餅', '粉餅', '潤色保濕霜', 'BB 霜', 'CC 霜', '遮瑕液', '遮瑕膏', '校色遮瑕', '定妝粉餅', '蜜粉', '定妝粉', '粉狀腮紅', '霜狀腮紅', '液態腮紅', '打亮', '修容'],
    itemSlugs: ['foundation', 'serum-foundation', 'cream-foundation', 'stick-foundation', 'cushion-foundation', 'powder-foundation', 'tinted-moisturizer', 'bb-cream', 'cc-cream', 'liquid-concealer', 'cream-concealer', 'color-corrector', 'pressed-powder', 'loose-powder', 'setting-powder', 'powder-blush', 'cream-blush', 'liquid-blush', 'highlighter', 'contour'],
    image: '/images/makeup/face.png',
  },
  { slug: 'eyebrow', name: 'Eyebrow', zhName: '眉毛', detail: 'Pencil · Gel · Powder', zhDetail: '眉筆 · 眉膠 · 眉粉', items: ['Brow Pencil', 'Brow Powder', 'Brow Gel', 'Brow Pomade'], zhItems: ['眉筆', '眉粉', '染眉膏', '眉膠／眉膏'], itemSlugs: ['brow-pencil', 'brow-powder', 'brow-gel', 'brow-pomade'], image: '/images/makeup/eyebrow.png' },
  { slug: 'eyes', name: 'Eyes', zhName: '眼妝', detail: 'Eyeshadow · Liner · Mascara', zhDetail: '眼影 · 眼線 · 睫毛膏', items: ['Eyeshadow', 'Eyeliner', 'Mascara', 'Eye Primer'], zhItems: ['眼影', '眼線', '睫毛膏', '眼部打底'], itemSlugs: ['eyeshadow', 'eyeliner', 'mascara', 'eye-primer'], image: '/images/makeup/eyes.png' },
  { slug: 'lips', name: 'Lips', zhName: '唇彩', detail: 'Lipstick · Lip Gloss · Lip Care', zhDetail: '口紅 · 唇蜜 · 唇部保養', items: ['Lipstick', 'Lip Gloss', 'Lip Tint', 'Lip Balm'], zhItems: ['口紅', '唇蜜', '唇釉／唇露', '護唇膏'], itemSlugs: ['lipstick', 'lip-gloss', 'lip-tint', 'lip-balm'], image: '/images/makeup/lips.png' },
]

const currentMakeupCategory = computed(() => {
  currentPageKey.value
  const segments = appPathname().split('/').filter(Boolean)
  if (segments[0] !== 'makeup' || !segments[1]) return null
  return makeupCategories.find(category => category.slug === segments[1]) || null
})
const currentMakeupProductSlug = computed(() => {
  currentPageKey.value
  return appPathname().split('/').filter(Boolean)[2] || ''
})
const visibleMakeupProducts = computed(() => {
  if (!currentMakeupCategory.value) return []
  return currentMakeupCategory.value.items.map((name, index) => ({
    id: `${currentMakeupCategory.value.slug}-${currentMakeupCategory.value.itemSlugs[index]}`,
    name,
    zhName: currentMakeupCategory.value.slug === 'eyebrow' && currentMakeupCategory.value.itemSlugs[index] === 'brow-pencil' ? '0.9mm 極細眉筆' : currentMakeupCategory.value.zhItems[index],
    slug: currentMakeupCategory.value.itemSlugs[index],
    image: currentMakeupCategory.value.slug === 'eyebrow' && currentMakeupCategory.value.itemSlugs[index] === 'brow-pencil'
      ? '/images/makeup/product-1.jpg'
      : currentMakeupCategory.value.slug === 'eyebrow' && currentMakeupCategory.value.itemSlugs[index] === 'brow-gel'
        ? '/images/makeup/product-3.png'
        : index === 0 ? currentMakeupCategory.value.image : makeupTextureImages[index % makeupTextureImages.length],
    gallery: currentMakeupCategory.value.slug === 'eyebrow' && currentMakeupCategory.value.itemSlugs[index] === 'brow-pencil'
      ? ['/images/makeup/product-1.jpg', '/images/makeup/product-2.png']
      : [
          currentMakeupCategory.value.slug === 'eyebrow' && currentMakeupCategory.value.itemSlugs[index] === 'brow-gel' ? '/images/makeup/product-3.png' : index === 0 ? currentMakeupCategory.value.image : makeupTextureImages[index % makeupTextureImages.length],
          makeupTextureImages[(index + 2) % makeupTextureImages.length],
        ],
    sku: currentMakeupCategory.value.slug === 'eyebrow' && currentMakeupCategory.value.itemSlugs[index] === 'brow-pencil' ? 'SI119S' : `SBG-${currentMakeupCategory.value.slug.slice(0, 3).toUpperCase()}-${String(index + 1).padStart(2, '0')}`,
    zhDetailHeading: currentMakeupCategory.value.slug === 'eyebrow' && currentMakeupCategory.value.itemSlugs[index] === 'brow-pencil' ? '精準定義 × 持久防水 × 旋轉式設計' : '專業配方 × 細緻妝效 × 品牌客製',
    description: `Custom ${name.toLowerCase()} developed for color, texture, precision and long-lasting performance.`,
    zhDescription: currentMakeupCategory.value.slug === 'eyebrow' && currentMakeupCategory.value.itemSlugs[index] === 'brow-pencil'
      ? '打造自然、細緻眉毛的終極工具。0.9mm 超細筆尖，專業設計用於精準填補稀疏區域，模仿單根眉毛，打造逼真、立體的眉妝。'
      : `可客製色彩、質地、精準度與持妝表現的${currentMakeupCategory.value.zhItems[index]}，適合打造專屬品牌系列。`,
    zhDetails: currentMakeupCategory.value.slug === 'eyebrow' && currentMakeupCategory.value.itemSlugs[index] === 'brow-pencil'
      ? [
          '防水抗汗配方，即使在潮濕或活動量大的情況下，也能讓眉毛保持完美形狀。',
          '柔滑、奶油般的筆芯容易上色，不拉扯、不結塊，妝感自然持久。',
          '便利旋轉式設計，無需削筆，隨時快速補妝。',
        ]
      : ['配方與色彩可依品牌需求客製。', '提供多元質地、妝效與包裝選擇。', '支援產品測試、包裝協調與量產。'],
  }))
})
const currentCatalogItem = computed(() => visibleMakeupProducts.value.find(item => item.slug === currentMakeupProductSlug.value) || null)
const recommendedMakeupProducts = computed(() => visibleMakeupProducts.value.filter(item => item.slug !== currentMakeupProductSlug.value).slice(0, 4))
const currentCatalogImage = computed(() => currentCatalogItem.value?.gallery.includes(selectedCatalogImage.value) ? selectedCatalogImage.value : currentCatalogItem.value?.gallery[0] || '')
watch(currentMakeupProductSlug, () => {
  recommendationsOpen.value = false
})
const catalogPageSize = 8
const paginatedMakeupProducts = computed(() => visibleMakeupProducts.value.slice(0, catalogVisibleCount.value))
const hasMoreCatalogProducts = computed(() => catalogVisibleCount.value < visibleMakeupProducts.value.length)
const loadMoreCatalogProducts = () => {
  catalogVisibleCount.value = Math.min(catalogVisibleCount.value + catalogPageSize, visibleMakeupProducts.value.length)
}
let catalogObserver
watch(catalogLoadTrigger, (element, previousElement) => {
  if (!catalogObserver) return
  if (previousElement) catalogObserver.unobserve(previousElement)
  if (element) catalogObserver.observe(element)
}, { flush: 'post' })

const cartCount = computed(() => cartItems.value.reduce((total, item) => total + item.quantity, 0))
const saveCart = () => localStorage.setItem('style-cart', JSON.stringify(cartItems.value))
const addToCart = (product) => {
  const existing = cartItems.value.find(item => item.id === product.id)
  if (existing) existing.quantity += 1
  else cartItems.value.push({ id: product.id, name: product.name, zhName: product.zhName, image: product.image, quantity: 1 })
  saveCart()
  cartOpen.value = true
}
const removeFromCart = (productId) => {
  cartItems.value = cartItems.value.filter(item => item.id !== productId)
  saveCart()
}

const toggleMakeupCategory = (categoryName) => {
  expandedMakeupCategory.value = expandedMakeupCategory.value === categoryName ? '' : categoryName
}

const makeupEditorialImages = ['/images/makeup/face.png', '/images/makeup/eyebrow.png', '/images/makeup/eyes.png', '/images/makeup/lips.png', '/images/makeup/hero.png']
const makeupTextureImages = [
  '/images/makeup/textures/foundation.png',
  '/images/makeup/textures/cream-blush.png',
  '/images/makeup/textures/highlighter.png',
  '/images/makeup/textures/lip-glaze.png',
  '/images/makeup/textures/eyeshadow.png',
  '/images/makeup/textures/gel.png',
]

const makeupProcess = [
  { number: '01', name: 'Product Selection', zhName: '產品選擇', image: '/images/makeup/hero.png' },
  { number: '02', name: 'Sampling', zhName: '打樣', image: '/images/makeup/face.png' },
  { number: '03', name: 'Sample Confirmation', zhName: '樣品確認', image: '/images/makeup/lips.png' },
  { number: '04', name: 'Quotation', zhName: '報價', image: '/images/makeup/eyebrow.png' },
  { number: '05', name: 'Packaging & Artwork', zhName: '包裝與設計', image: '/images/makeup/hero.png' },
  { number: '06', name: 'Bulk Production', zhName: '正式量產', image: '/images/makeup/eyes.png' },
  { number: '07', name: 'Delivery', zhName: '出貨交付', image: '/images/makeup/face.png' },
  { number: '08', name: 'After-Sales Support', zhName: '售後服務', image: '/images/makeup/lips.png' },
]

const sunCareNavCategories = [
  { name: 'About', zhName: '關於保養品', items: ['Our Approach'], zhItems: ['品牌理念'] },
  { name: 'Cleansers', zhName: '潔面產品', items: ['Foam Cleanser', 'Cleansing Oil'], zhItems: ['潔面乳', '卸妝油'] },
  // { name: 'Toners', zhName: '化妝水', items: ['Hydrating Toner'], zhItems: ['保濕化妝水'] },
  // { name: 'Serums', zhName: '精華液', items: ['Face Serum', 'Essence'], zhItems: ['臉部精華', '精華露'] },
  // { name: 'Moisturizers', zhName: '保濕產品', items: ['Face Cream', 'Moisturizer'], zhItems: ['乳霜', '保濕乳'] },
  // { name: 'Masks', zhName: '面膜', items: ['Sheet Mask', 'Cream Mask'], zhItems: ['片狀面膜', '霜狀面膜'] },
  // { name: 'Special Care', zhName: '特殊保養', items: ['Ampoule', 'Body Care'], zhItems: ['安瓶', '身體保養'] },
]

const sunCareCategories = [
  { name: 'Cleansers', zhName: '潔面產品', detail: 'Cleansing · Fresh Start', zhDetail: '溫和清潔 · 潔淨煥新', image: 'photo-1556229010-6c3f2c9ca5f8' },
  { name: 'Toners', zhName: '化妝水', detail: 'Hydration · Skin Balance', zhDetail: '補水保濕 · 調理膚況', image: 'photo-1601049541289-9b1b7bbbfe19' },
  { name: 'Serum & Essences', zhName: '精華液與精華露', detail: 'Targeted Care · Active Ingredients', zhDetail: '高效修護 · 精準保養', image: 'photo-1556228578-0d85b1a4d571' },
  { name: 'Spray & Mist', zhName: '噴霧與化妝水', detail: 'Refreshing · On-the-Go', zhDetail: '清新補水 · 隨時保養', image: 'photo-1608248543803-ba4f8c70ae0b' },
  { name: 'Cream & Moisturizers', zhName: '乳霜與保濕產品', detail: 'Nourishing · Barrier Support', zhDetail: '滋養潤澤 · 屏障呵護', image: 'photo-1611930022073-b7a4ba5fcccd' },
  { name: 'Masks', zhName: '面膜', detail: 'Intensive Care · Skin Reset', zhDetail: '密集修護 · 深度滋養', image: 'photo-1601049541289-9b1b7bbbfe19' },
  { name: 'Specialized Skincare', zhName: '特殊保養', detail: 'Focused Solutions · Custom Care', zhDetail: '專業配方 · 客製護理', image: 'photo-1556229010-6c3f2c9ca5f8' },
  { name: 'Body Care', zhName: '身體保養', detail: 'Head-to-Toe · Daily Ritual', zhDetail: '全身呵護 · 日常儀式', image: 'photo-1556228578-0d85b1a4d571' },
  { name: 'Ampoule', zhName: '安瓶', detail: 'Concentrated · Intensive Care', zhDetail: '高濃度精華 · 密集修護', image: 'photo-1608248543803-ba4f8c70ae0b' },
  { name: "Men's Grooming", zhName: '男士理容', detail: 'Simple Routine · Modern Care', zhDetail: '簡約程序 · 現代保養', image: 'photo-1611930022073-b7a4ba5fcccd' },
]

const sunCareSolutions = [
  { name: 'Hydration & Moisture', zhName: '補水與保濕', category: 'HYDRATION', zhCategory: '補水保濕', image: 'photo-1608248543803-ba4f8c70ae0b' },
  { name: 'Brightening & Radiance', zhName: '亮白與透亮', category: 'RADIANCE', zhCategory: '透亮光采', image: 'photo-1601049541289-9b1b7bbbfe19' },
  { name: 'Anti-Aging', zhName: '抗老修護', category: 'AGE SUPPORT', zhCategory: '青春修護', image: 'photo-1556229010-6c3f2c9ca5f8' },
  { name: 'Sensitive Skin Care', zhName: '敏弱肌呵護', category: 'GENTLE SKINCARE', zhCategory: '溫和保養', image: 'photo-1611930022073-b7a4ba5fcccd' },
  { name: 'Acne & Oil Control', zhName: '痘肌與控油', category: 'BALANCE & CLARITY', zhCategory: '油水平衡', image: 'photo-1556228578-0d85b1a4d571' },
  { name: 'Hybrid Skincare', zhName: '妝養合一', category: 'SKINCARE BENEFITS', zhCategory: '多效保養', image: 'photo-1522335789203-aabd1fc54bc9' },
]
const moveSunCareSolutions = (direction) => {
  sunCareSolutionIndex.value = (sunCareSolutionIndex.value + direction + sunCareSolutions.length) % sunCareSolutions.length
}

const sunCareProcess = [
  { number: '01', name: 'Product Selection', zhName: '產品選擇', image: 'photo-1608248543803-ba4f8c70ae0b' },
  { number: '02', name: 'Sampling', zhName: '打樣', image: 'photo-1601049541289-9b1b7bbbfe19' },
  { number: '03', name: 'Sample Confirmation', zhName: '樣品確認', image: 'photo-1556229010-6c3f2c9ca5f8' },
  { number: '04', name: 'Quotation', zhName: '報價', image: 'photo-1556228578-0d85b1a4d571' },
  { number: '05', name: 'Packaging & Artwork', zhName: '包裝與設計', image: 'photo-1611930022073-b7a4ba5fcccd' },
  { number: '06', name: 'Bulk Production', zhName: '正式量產', image: 'photo-1608248543803-ba4f8c70ae0b' },
  { number: '07', name: 'Delivery', zhName: '出貨交付', image: 'photo-1601049541289-9b1b7bbbfe19' },
  { number: '08', name: 'After-Sales Support', zhName: '售後服務', image: 'photo-1556229010-6c3f2c9ca5f8' },
]

const solutions = [
  { name: 'Skin-Like Beauty', zhName: '宛若原生的妝感', category: 'MAKEUP', zhCategory: '彩妝', image: 'photo-1556229010-6c3f2c9ca5f8' },
  { name: 'Long-Wear & Hydration', zhName: '持妝與保濕', category: 'SKINCARE', zhCategory: '保養', image: 'photo-1608248543803-ba4f8c70ae0b' },
  { name: 'Hydration & Glow', zhName: '水潤透亮', category: 'FORMULATION', zhCategory: '配方研發', image: 'photo-1556228578-0d85b1a4d571' },
  { name: 'Soft Focus', zhName: '柔焦妝效', category: 'COLOR COSMETICS', zhCategory: '彩妝品', image: 'photo-1522335789203-aabd1fc54bc9' },
  { name: 'Clean Beauty', zhName: '純淨美妝', category: 'CONSCIOUS FORMULAS', zhCategory: '純淨配方', image: 'photo-1608248543803-ba4f8c70ae0b' },
  { name: 'Sensitive Skin Care', zhName: '敏弱肌呵護', category: 'GENTLE SKINCARE', zhCategory: '溫和保養', image: 'photo-1611930022073-b7a4ba5fcccd' },
  { name: 'Custom Color Stories', zhName: '品牌專屬色彩', category: 'CUSTOM COLOR', zhCategory: '客製色彩', image: 'photo-1522335789203-aabd1fc54bc9' },
  { name: 'Beauty Essentials', zhName: '日常美妝必備', category: 'EVERYDAY BEAUTY', zhCategory: '日常美妝', image: 'photo-1596462502278-27bfdc403348' },
  { name: 'Hybrid Beauty', zhName: '妝養合一', category: 'MAKEUP MEETS SKINCARE', zhCategory: '彩妝保養結合', image: 'photo-1601049541289-9b1b7bbbfe19' },
  { name: 'Daily Sun Protection', zhName: '日常防曬提案', category: 'SUN CARE', zhCategory: '防曬保養', image: 'photo-1608248543803-ba4f8c70ae0b' },
  { name: 'Barrier Care', zhName: '肌膚屏障修護', category: 'BARRIER SUPPORT', zhCategory: '屏障呵護', image: 'photo-1611930022073-b7a4ba5fcccd' },
  { name: 'Sensory Textures', zhName: '感官質地探索', category: 'TEXTURE INNOVATION', zhCategory: '質地創新', image: 'photo-1601049541289-9b1b7bbbfe19' },
]
const moveMakeupSolutionPage = (direction) => {
  makeupSolutionPage.value = (makeupSolutionPage.value + direction + solutions.length) % solutions.length
}
const makeupSolutionCardStyle = (index) => {
  let offset = index - makeupSolutionPage.value
  if (offset > solutions.length / 2) offset -= solutions.length
  if (offset < -solutions.length / 2) offset += solutions.length
  const distance = Math.abs(offset)
  return {
    '--card-offset': offset,
    '--card-scale': distance === 0 ? 1 : distance === 1 ? .84 : .7,
    '--card-opacity': distance > 2 ? 0 : distance === 2 ? .55 : distance === 1 ? .78 : 1,
    '--card-z': 10 - distance,
    pointerEvents: distance > 2 ? 'none' : 'auto',
  }
}
const solutionPageCount = computed(() => Math.ceil(solutions.length / solutionPageSize))
const solutionPages = computed(() => Array.from({ length: solutionPageCount.value }, (_, pageIndex) => ({
  key: `page-${pageIndex}`,
  logicalIndex: pageIndex,
  items: Array.from({ length: solutionPageSize }, (_, cardIndex) => solutions[(pageIndex * solutionPageSize + cardIndex) % solutions.length]),
})))
const solutionTrackPages = computed(() => {
  if (solutionTransitionPages.value) return solutionTransitionPages.value
  if (solutionWrapToFirst.value) return [...solutionPages.value, { ...solutionPages.value[0], key: 'clone-first' }]
  return solutionPages.value
})

const inspirations = [
  { name: 'Makeup x Skincare', zhName: '彩妝與保養的交會', category: 'HYBRID BEAUTY', zhCategory: '混合美妝', image: 'photo-1540555700478-4be289fbecef' },
  { name: 'Multifunctional Beauty', zhName: '多效合一美妝', category: 'SMART FORMULAS', zhCategory: '智慧配方', image: 'photo-1611930022073-b7a4ba5fcccd' },
  { name: 'Innovative Formats', zhName: '創新產品形式', category: 'NEW TEXTURES', zhCategory: '全新質地', image: 'photo-1487412720507-e7ab37603c6f' },
  { name: 'Nostalgic', zhName: '復古美妝靈感', category: 'BEAUTY STORIES', zhCategory: '美妝故事', image: 'photo-1608248543803-ba4f8c70ae0b' },
]

const makeupInspirationItems = [
  ...inspirations,
  { name: 'Newstalgia', zhName: '新復古美學', category: 'COLOR STORY', zhCategory: '色彩故事' },
  { name: 'Statement Color', zhName: '個性色彩', category: 'MAKEUP TREND', zhCategory: '彩妝趨勢' },
]

const makeupInsights = [
  { name: 'Skin-Like Beauty', zhName: '原生肌妝感', category: 'BEAUTY INSIGHT', zhCategory: '美妝洞察' },
  { name: 'Long-Wear', zhName: '長效持妝', category: 'PERFORMANCE', zhCategory: '產品表現' },
  { name: 'Hydration & Glow', zhName: '水潤光澤', category: 'FORMULATION', zhCategory: '配方趨勢' },
  { name: 'Soft Focus', zhName: '柔焦妝效', category: 'FINISH', zhCategory: '妝效靈感' },
  { name: 'Oil Control', zhName: '清爽控油', category: 'SKIN NEED', zhCategory: '肌膚需求' },
  { name: 'Multifunctional', zhName: '多效合一', category: 'SMART BEAUTY', zhCategory: '智慧美妝' },
]

const moveMakeupFeature = (type, direction) => {
  const target = type === 'inspiration' ? makeupInspirationFocus : makeupInsightFocus
  const items = type === 'inspiration' ? makeupInspirationItems : makeupInsights
  target.value = (target.value + direction + items.length) % items.length
}

const questions = [
  { question: 'What is the minimum order quantity (MOQ)?', zhQuestion: '最低訂購量（MOQ）是多少？', answer: 'MOQ depends on the formula, packaging, and project scope. Share your brief with our team and we will recommend the right starting point.', zhAnswer: '最低訂購量會依配方、包裝與專案範圍而有所不同。歡迎提供需求，我們會協助評估合適的起訂方式。' },
  { question: 'Can you assist with packaging design and sourcing?', zhQuestion: '可以協助包裝設計與採購嗎？', answer: 'Yes. We support packaging concept development, component sourcing, artwork coordination, and production.', zhAnswer: '可以。我們提供包裝概念開發、包材採購、設計稿協調與量產支援。' },
  { question: 'How long does product development take?', zhQuestion: '產品開發需要多久？', answer: 'Timing varies by formula complexity, testing, and packaging. We provide a project schedule after reviewing your requirements.', zhAnswer: '開發時程依配方複雜度、測試與包裝需求而異；了解需求後，我們會提供專案時程規劃。' },
  { question: 'Do you provide regulatory support for different markets?', zhQuestion: '能提供不同市場的法規支援嗎？', answer: 'Our team can help coordinate product documentation and compliance requirements for your target markets.', zhAnswer: '團隊可協助整理產品文件，並配合目標市場的法規與合規需求。' },
  { question: 'Can you develop a product from our own concept?', zhQuestion: '可以依照我們的構想開發產品嗎？', answer: 'Absolutely. We work with your product brief, target audience, performance goals, and brand direction.', zhAnswer: '沒問題。我們會依據產品需求、目標客群、產品表現與品牌方向共同開發。' },
  { question: 'What certifications and quality systems do you have?', zhQuestion: '具備哪些認證與品質管理制度？', answer: 'Our manufacturing and quality processes follow documented standards. Contact us for current certification details.', zhAnswer: '製造與品質流程依據標準化制度執行，歡迎聯絡我們索取最新認證資訊。' },
]

const beautyHubSections = [
  {
    number: '01', id: 'hub-solutions', eyebrow: 'SOLUTIONS', zhEyebrow: '產品方案',
    title: "What Your Brand’s Needs?", zhTitle: '找到適合品牌的產品方向',
    description: 'Explore product solutions across makeup, skincare, sun care and hybrid beauty.', zhDescription: '從彩妝、保養、防曬到妝養合一，探索符合品牌定位與市場需求的產品方向。',
    items: [
      { name: 'Makeup', zhName: '彩妝', detail: 'Color, texture and multi-functional formulas.', zhDetail: '色彩、質地與多功能配方。', image: '/images/makeup/textures/foundation.png' },
      { name: 'Skincare', zhName: '保養品', detail: 'Effective ingredients and sensorial textures.', zhDetail: '有效成分與細緻膚感。', image: '/images/makeup/textures/gel.png' },
      { name: 'Sun Care', zhName: '防曬', detail: 'Everyday protection with skincare benefits.', zhDetail: '結合日常防護與保養體驗。', image: '/images/sun-care-hero.png' },
      { name: 'Hybrid Solutions', zhName: '妝養合一', detail: 'Makeup + skincare innovation.', zhDetail: '融合彩妝與保養的創新概念。', image: '/images/makeup/textures/cream-blush.png' },
    ],
  },
  {
    number: '02', id: 'hub-inspirations', eyebrow: 'INSPIRATIONS', zhEyebrow: '靈感趨勢',
    title: 'Creating What’s Next', zhTitle: '創造下一個美妝趨勢',
    description: 'Get inspired by emerging beauty trends, innovative concepts and real product ideas.', zhDescription: '從新興美妝趨勢、創新概念與產品靈感中，找到品牌下一步的開發方向。',
    items: [
      { name: 'Trend Forecast', zhName: '趨勢預測', detail: 'Future beauty trends and color direction.', zhDetail: '未來美妝趨勢與色彩方向。', image: '/images/makeup/textures/eyeshadow.png' },
      { name: 'Concept Inspiration', zhName: '概念靈感', detail: 'Creative ideas for new launches.', zhDetail: '適合新品開發的創意概念。', image: '/images/makeup/hero.png' },
      { name: 'Ingredient Focus', zhName: '成分焦點', detail: 'Explore functional ingredients.', zhDetail: '探索具市場話題的機能成分。', image: '/images/makeup/textures/gel.png' },
      { name: 'Application Ideas', zhName: '應用提案', detail: 'New ways to create unique products.', zhDetail: '打造差異化產品的應用提案。', image: '/images/makeup/textures/lip-glaze.png' },
    ],
  },
  {
    number: '03', id: 'hub-blog', eyebrow: 'BLOG', zhEyebrow: '專業文章',
    title: 'Ideas Into Insights', zhTitle: '讓靈感成為專業洞察',
    description: 'Gain practical knowledge from formulation and ingredients to packaging, regulation and market opportunities.', zhDescription: '從配方成分、包裝設計到市場趨勢，以專業內容協助品牌掌握開發方向。',
    items: [
      { name: 'Beauty Market Trends to Watch', zhName: '值得關注的美妝市場趨勢', category: 'MARKET TRENDS', zhCategory: '市場趨勢', detail: 'How consumer priorities, sensorial textures and hybrid formats are shaping the next beauty launches.', zhDetail: '從消費需求、感官質地到妝養合一，掌握下一波美妝產品的市場方向。', date: '2026.11.02', image: '/images/makeup/face.png' },
      { name: 'How Texture Shapes Product Experience', zhName: '質地如何影響產品使用體驗', category: 'FORMULATION', zhCategory: '配方技術', detail: 'A practical look at spreadability, finish and after-feel when developing a new formula.', zhDetail: '從延展性、妝效到使用後膚感，理解新品配方開發的質地設計。', date: '2026.10.24', image: '/images/makeup/textures/highlighter.png' },
      { name: 'Choosing Packaging for a New Beauty Line', zhName: '新產品線如何選擇合適包裝', category: 'PACKAGING', zhCategory: '包裝設計', detail: 'Key questions to consider across product compatibility, brand expression and production.', zhDetail: '從產品相容性、品牌呈現到量產條件，整理包裝選擇的重要考量。', date: '2026.10.12', image: '/banner2.png' },
      { name: 'From Product Idea to Brand Portfolio', zhName: '從單一產品到完整品牌系列', category: 'BRAND DEVELOPMENT', zhCategory: '品牌發展', detail: 'Build a focused launch plan that can grow into a clear and coherent product portfolio.', zhDetail: '從核心商品出發，建立能持續延伸且定位清晰的品牌產品組合。', date: '2026.09.28', image: '/images/makeup/textures/cream-blush.png' },
    ],
  },
]
const activeBeautyHubSection = computed(() => beautyHubSections.find(section => section.id === beautyHubTab.value) || beautyHubSections[0])

const rotateItems = (items, index) => [...items.slice(index), ...items.slice(0, index)]
const setSolutionsPage = async (pageIndex) => {
  if (solutionTransitionPages.value || solutionWrapToFirst.value || pageIndex === solutionIndex.value) return
  if (solutionIndex.value === solutionPageCount.value - 1 && pageIndex === 0) {
    solutionWrapToFirst.value = true
    solutionTransitionDuration.value = 0
    solutionTrackIndex.value = solutionIndex.value
    await nextTick()
    requestAnimationFrame(() => {
      solutionIndex.value = 0
      solutionTransitionDuration.value = 700
      solutionTrackIndex.value = solutionPageCount.value
    })
    return
  }
  const currentPage = solutionPages.value[solutionIndex.value]
  const targetPage = solutionPages.value[pageIndex]
  solutionTransitionPages.value = [currentPage, targetPage]
  solutionTransitionDuration.value = 0
  solutionTrackIndex.value = 0
  await nextTick()
  requestAnimationFrame(() => {
    solutionIndex.value = pageIndex
    solutionTransitionDuration.value = 700
    solutionTrackIndex.value = 1
  })
}
const finishSolutionsTransition = (event) => {
  if (event.target !== event.currentTarget || event.propertyName !== 'transform') return
  if (solutionWrapToFirst.value && solutionTrackIndex.value === solutionPageCount.value) {
    solutionTransitionDuration.value = 0
    solutionWrapToFirst.value = false
    solutionIndex.value = 0
    solutionTrackIndex.value = 0
    nextTick(() => requestAnimationFrame(() => { solutionTransitionDuration.value = 700 }))
    return
  }
  if (!solutionTransitionPages.value || solutionTrackIndex.value !== 1) return
  solutionTransitionDuration.value = 0
  solutionTransitionPages.value = null
  solutionTrackIndex.value = solutionIndex.value
  nextTick(() => requestAnimationFrame(() => { solutionTransitionDuration.value = 700 }))
}
const moveCarousel = (carousel, direction) => {
  if (carousel === 'solutions') {
    setSolutionsPage((solutionIndex.value + direction + solutionPageCount.value) % solutionPageCount.value)
  } else inspirationIndex.value = (inspirationIndex.value + direction + inspirations.length) % inspirations.length
}
let solutionCarouselTimer
const scheduleSolutionsCarousel = () => {
  window.clearTimeout(solutionCarouselTimer)
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches || solutionsPaused.value) return
  solutionCarouselTimer = window.setTimeout(() => {
    moveCarousel('solutions', 1)
    scheduleSolutionsCarousel()
  }, 3000)
}
const pauseSolutionsCarousel = () => {
  solutionsPaused.value = true
  window.clearTimeout(solutionCarouselTimer)
}
const resumeSolutionsAutoplay = () => {
  solutionsPaused.value = false
  scheduleSolutionsCarousel()
}
const updateInquiryFrameHeight = (event) => {
  if (event.source !== inquiryFrame.value?.contentWindow || event.data?.type !== 'style-beauty-inquiry-height') return
  const height = Number(event.data.height)
  if (Number.isFinite(height)) inquiryFrameHeight.value = Math.max(620, Math.min(height + 4, 1800))
}
onMounted(() => {
  scheduleSolutionsCarousel()
  window.addEventListener('message', updateInquiryFrameHeight)
  catalogObserver = new IntersectionObserver((entries) => {
    if (entries.some(entry => entry.isIntersecting)) loadMoreCatalogProducts()
  }, { rootMargin: '0px 0px 420px 0px' })
  if (catalogLoadTrigger.value) catalogObserver.observe(catalogLoadTrigger.value)
})
onUnmounted(() => {
  window.clearTimeout(solutionCarouselTimer)
  catalogObserver?.disconnect()
  window.removeEventListener('message', updateInquiryFrameHeight)
})
</script>

<template>
  <div id="top" class="site-shell" @click="handleInternalNavigation">
    <header class="site-header">
      <div class="utility-bar">
        <div class="utility-contact">
          <a href="tel:+886423370043">Tel : +886-4-23370043</a>
          <a class="utility-email" href="mailto:style-diana@stylebeautygroup.com">Mail : style-diana@stylebeautygroup.com</a>
        </div>
        <div class="utility-right">
          <span class="follow-label">Follow Us:</span>
          <a class="social-link facebook-link" href="https://www.facebook.com/" aria-label="Facebook">f</a>
          <a class="social-link" href="https://www.instagram.com/" aria-label="Instagram"><svg viewBox="0 0 24 24" aria-hidden="true"><rect x="3" y="3" width="18" height="18" rx="5"/><circle cx="12" cy="12" r="4"/><circle class="social-dot" cx="18" cy="6" r="1"/></svg></a>
          <a class="social-link" href="https://www.youtube.com/@stylebeautygroup6112" target="_blank" rel="noopener noreferrer" aria-label="YouTube（在新分頁開啟）"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M22 12s0-3.4-.45-5.05a2.6 2.6 0 0 0-1.83-1.83C18.1 4.67 12 4.67 12 4.67s-6.1 0-7.72.45a2.6 2.6 0 0 0-1.83 1.83C2 8.6 2 12 2 12s0 3.4.45 5.05a2.6 2.6 0 0 0 1.83 1.83c1.62.45 7.72.45 7.72.45s6.1 0 7.72-.45a2.6 2.6 0 0 0 1.83-1.83C22 15.4 22 12 22 12Z"/><path class="play-mark" d="m10 15.3 5.2-3.3L10 8.7z"/></svg></a>
          <a class="social-link tiktok-link" href="https://www.tiktok.com/" aria-label="TikTok">♪</a>
          <label class="language-picker"><span class="visually-hidden">Language</span><select :value="language" aria-label="Language" @change="setLanguage"><option value="zh">中文</option><option value="en">English</option></select></label>
        </div>
      </div>

      <div class="main-header">
        <a class="wordmark" href="/" aria-label="Style Beauty Group 首頁">
          <img class="wordmark-logo" src="/logo_1.svg" alt="Style Beauty Group" />
        </a>

        <button class="menu-toggle" type="button" :aria-expanded="menuOpen" aria-label="切換導覽選單" @click="menuOpen = !menuOpen">
          <span></span><span></span>
        </button>

        <nav class="main-nav" :class="{ 'is-open': menuOpen }" aria-label="主要導覽">
          <div class="nav-dropdown nav-dropdown--with-toggle" :class="{ 'is-expanded': aboutMenuOpen }">
            <a class="nav-dropdown-toggle" :class="{ active: currentPageKey === 'about' }" href="/about" :aria-current="currentPageKey === 'about' ? 'page' : undefined">{{ language === 'zh' ? '關於' : copy.nav[1] }}</a>
            <button class="nav-dropdown-mobile-toggle" type="button" :aria-expanded="aboutMenuOpen" :aria-label="language === 'zh' ? '展開關於選單' : 'Expand about menu'" @click="aboutMenuOpen = !aboutMenuOpen"><span aria-hidden="true">⌄</span></button>
            <div class="nav-dropdown-menu">
              <a href="/about" :aria-current="currentPageKey === 'about' ? 'page' : undefined" @click="aboutMenuOpen = false; menuOpen = false">{{ language === 'zh' ? '關於' : 'About' }}</a>
              <a href="/#turnkey" @click="aboutMenuOpen = false; menuOpen = false">{{ language === 'zh' ? '一站式解決方案' : 'Turnkey Solutions' }}</a>
              <a href="/#faq" @click="aboutMenuOpen = false; menuOpen = false">FAQ</a>
            </div>
          </div>
          <div class="nav-dropdown nav-dropdown--makeup nav-dropdown--with-toggle" :class="{ 'is-expanded': makeupMenuOpen }">
            <a class="nav-dropdown-toggle" :class="{ active: currentPageKey === 'makeup' || currentMakeupCategory }" href="/makeup" :aria-current="currentPageKey === 'makeup' || currentMakeupCategory ? 'page' : undefined">{{ copy.nav[2] }}</a>
            <button class="nav-dropdown-mobile-toggle" type="button" :aria-expanded="makeupMenuOpen" :aria-label="language === 'zh' ? '展開彩妝品類' : 'Expand makeup categories'" @click="makeupMenuOpen = !makeupMenuOpen"><span aria-hidden="true">⌄</span></button>
            <div class="nav-dropdown-menu">
              <a href="/makeup" @click="aboutMenuOpen = false; makeupMenuOpen = false; menuOpen = false">{{ language === 'zh' ? '眉毛' : 'Brows' }}</a>
              <a href="/makeup" @click="aboutMenuOpen = false; makeupMenuOpen = false; menuOpen = false">{{ language === 'zh' ? '眼睛' : 'Eyes' }}</a>
              <a href="/makeup" @click="aboutMenuOpen = false; makeupMenuOpen = false; menuOpen = false">{{ language === 'zh' ? '嘴唇' : 'Lips' }}</a>
              <a href="/makeup" @click="aboutMenuOpen = false; makeupMenuOpen = false; menuOpen = false">{{ language === 'zh' ? '臉孔' : 'Face' }}</a>
              <a href="/sun-care" @click="aboutMenuOpen = false; makeupMenuOpen = false; menuOpen = false">{{ language === 'zh' ? '防曬' : 'Sun Care' }}</a>
            </div>
          </div>
          <a href="/sun-care" :class="{ active: currentPageKey === 'sun-care' }" :aria-current="currentPageKey === 'sun-care' ? 'page' : undefined">{{ copy.nav[3] }}</a>
          <a href="/skincare" :class="{ active: currentPageKey === 'skincare' }" :aria-current="currentPageKey === 'skincare' ? 'page' : undefined">{{ copy.nav[4] }}</a>
          <a href="/mens-care" :class="{ active: currentPageKey === 'mens-care' }" :aria-current="currentPageKey === 'mens-care' ? 'page' : undefined">{{ copy.nav[5] }}</a>
          <a href="/beauty-hub" :class="{ active: currentPageKey === 'beauty-hub' }" :aria-current="currentPageKey === 'beauty-hub' ? 'page' : undefined">{{ language === 'zh' ? '美妝專區' : 'BEAUTY HUB' }}</a>
          <!-- <a href="/video" :class="{ active: currentPageKey === 'video' }" :aria-current="currentPageKey === 'video' ? 'page' : undefined">{{ copy.nav[6] }}</a> -->
          <a href="/contact" :class="{ active: currentPageKey === 'contact' }" :aria-current="currentPageKey === 'contact' ? 'page' : undefined">{{ copy.nav[7] }}</a>
        </nav>

        <div class="header-actions">
          <button class="bag-link" type="button" :aria-expanded="cartOpen" :aria-label="language === 'zh' ? `購物車，共 ${cartCount} 件商品` : `Cart, ${cartCount} items`" @click="cartOpen = true">
            <svg viewBox="0 0 32 32" aria-hidden="true"><path d="M3 5h4l3.2 15.1a2 2 0 0 0 2 1.6h12.5a2 2 0 0 0 1.9-1.4L30 10H8"/><path d="M12 26.5h.01M24 26.5h.01"/><circle cx="12" cy="26" r="1.5"/><circle cx="24" cy="26" r="1.5"/></svg>
            <span v-if="cartCount" class="bag-count">{{ cartCount }}</span>
          </button>
          <button class="icon-button search-trigger" type="button" :aria-expanded="searchOpen" :aria-label="language === 'zh' ? '搜尋' : 'Search'" @click="searchOpen = !searchOpen"><svg viewBox="0 0 32 32" aria-hidden="true"><circle cx="13.5" cy="13.5" r="9.5"/><path d="m21 21 8 8"/></svg></button>
        </div>
      </div>
      <form v-if="searchOpen" class="search-panel" role="search" @submit.prevent>
        <label for="site-search">{{ copy.search }}</label>
        <div class="search-field">
          <input id="site-search" v-model="searchQuery" type="search" :placeholder="copy.searchPlaceholder" autofocus />
          <button type="button" :aria-label="language === 'zh' ? '關閉搜尋' : 'Close search'" @click="searchOpen = false">×</button>
        </div>
      </form>
    </header>

    <Transition name="cart-fade">
      <div v-if="cartOpen" class="cart-overlay" @click.self="cartOpen = false">
        <aside class="cart-drawer" :aria-label="language === 'zh' ? '購物車' : 'Shopping cart'">
          <div class="cart-drawer-header"><div><p class="eyebrow">{{ language === 'zh' ? '商品詢價清單' : 'PRODUCT INQUIRY LIST' }}</p><h2>{{ language === 'zh' ? '購物車' : 'Your Cart' }}</h2></div><button type="button" :aria-label="language === 'zh' ? '關閉購物車' : 'Close cart'" @click="cartOpen = false">×</button></div>
          <div v-if="cartItems.length" class="cart-items">
            <article v-for="item in cartItems" :key="item.id" class="cart-item">
              <img :src="assetPath(item.image)" :alt="language === 'zh' ? item.zhName : item.name" />
              <div><strong>{{ language === 'zh' ? item.zhName : item.name }}</strong><span>{{ language === 'zh' ? `數量：${item.quantity}` : `Quantity: ${item.quantity}` }}</span><button type="button" @click="removeFromCart(item.id)">{{ language === 'zh' ? '移除' : 'Remove' }}</button></div>
            </article>
          </div>
          <div v-else class="cart-empty"><span aria-hidden="true">◇</span><p>{{ language === 'zh' ? '購物車目前是空的' : 'Your cart is empty' }}</p></div>
          <div class="cart-drawer-footer"><a class="button button-primary" href="/contact" @click="cartOpen = false">{{ language === 'zh' ? '前往產品洽詢' : 'CONTINUE TO INQUIRY' }} <span aria-hidden="true">→</span></a></div>
        </aside>
      </div>
    </Transition>

    <Transition name="route" mode="out-in">
    <main v-if="!currentPage" key="home">
      <section id="home" class="hero" aria-labelledby="hero-title">
        <img class="hero-image" src="/banner2.png" alt="Style Beauty Group 美妝產品與品牌主視覺" />
        <h1 class="visually-hidden" id="hero-title">{{ copy.heroTitle }}</h1>
        <div class="hero-shade"></div>
        <div class="hero-copy">
          <p class="eyebrow">{{ copy.heroEyebrow }}</p>
          <h2 class="hero-mobile-title">{{ copy.heroTitle }}</h2>
          <p class="hero-description">{{ copy.heroDescription }}</p>
          <div class="hero-actions"><a class="button button-primary" href="/makeup">{{ copy.heroMakeup }} <span aria-hidden="true">↗</span></a><a class="button button-secondary" href="/skincare">{{ copy.heroSkincare }} <span aria-hidden="true">↗</span></a></div>
        </div>
        <p class="hero-index"><span>01</span> / 03</p>
        <span class="hero-caption">FORMULATED WITH PURPOSE · MADE IN TAIWAN</span>
      </section>

      <section id="about" class="intro section-pad">
        <div class="intro-image-wrap">
          <img src="/banner%20p%20.png" alt="粉底、唇彩與乳霜的化妝品內料質地" loading="lazy" />
        </div>
        <div class="intro-copy">
          <p class="eyebrow">{{ copy.aboutEyebrow }}</p>
          <h2 class="multiline-heading">{{ copy.aboutTitle }}</h2>
          <p class="body-copy">{{ copy.aboutBody }}</p>
          <a class="button button-primary" href="/about">{{ copy.aboutLink }} <span aria-hidden="true">↗</span></a>
        </div>
      </section>

      <section id="brands" class="why-section section-pad">
        <div class="why-heading"><p class="eyebrow">{{ copy.whyEyebrow }}</p><h2>{{ copy.whyTitle }}</h2><p>{{ copy.whySubtitle }}</p></div>
        <div class="feature-grid">
          <article class="feature-item"><span class="feature-icon"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M8 3h8M9 3v5l-4.5 8.2A3.2 3.2 0 0 0 7.3 21h9.4a3.2 3.2 0 0 0 2.8-4.8L15 8V3M7 14h10"/><path d="M9 17h.01M12 17h.01M15 17h.01"/></svg></span><strong>{{ copy.featureExperience }}</strong><p>{{ copy.feature1 }}</p></article>
          <article class="feature-item"><span class="feature-icon"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="m9.7 3.8.5-1.3h3.6l.5 1.3a8.6 8.6 0 0 1 1.7.7l1.3-.5 2.5 2.5-.5 1.3c.3.5.5 1.1.7 1.7l1.3.5v3.6l-1.3.5a8.6 8.6 0 0 1-.7 1.7l.5 1.3-2.5 2.5-1.3-.5c-.5.3-1.1.5-1.7.7l-.5 1.3h-3.6l-.5-1.3a8.6 8.6 0 0 1-1.7-.7l-1.3.5-2.5-2.5.5-1.3a8.6 8.6 0 0 1-.7-1.7L2.7 13v-3.6L4 8.9c.2-.6.4-1.2.7-1.7l-.5-1.3 2.5-2.5 1.3.5c.5-.3 1.1-.5 1.7-.7Z"/><circle cx="12" cy="11.2" r="3.1"/></svg></span><strong>{{ copy.featureCustom }}</strong><p>{{ copy.feature2 }}</p></article>
          <article class="feature-item"><span class="feature-icon"><svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="9.5"/><path d="M2.8 12h18.4M12 2.5c2.4 2.6 3.6 5.8 3.6 9.5s-1.2 6.9-3.6 9.5c-2.4-2.6-3.6-5.8-3.6-9.5s1.2-6.9 3.6-9.5Z"/><path d="M4.6 6.5h14.8M4.6 17.5h14.8"/></svg></span><strong>{{ copy.featureGlobal }}</strong><p>{{ copy.feature3 }}</p></article>
          <article class="feature-item"><span class="feature-icon"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3v5M5 8h14M5 8v4m14-4v4M3 12h4m10 0h4M5 12v4m14-4v4M3 16h4m10 0h4"/><rect x="9" y="2" width="6" height="5" rx="1"/><rect x="1.5" y="11" width="6" height="5" rx="1"/><rect x="16.5" y="11" width="6" height="5" rx="1"/><path d="M12 7v2H5v2m7-2h7v2"/></svg></span><strong>{{ copy.featureQuality }}</strong><p>{{ copy.feature4 }}</p></article>
          <article class="feature-item"><span class="feature-icon"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 2.5 20 5v6.2c0 5-3.3 8.5-8 10.3-4.7-1.8-8-5.3-8-10.3V5l8-2.5Z"/><path d="m8.5 11.8 2.3 2.3 4.8-5"/></svg></span><strong>{{ copy.featureGmp }}</strong><p>{{ copy.feature5 }}</p></article>
        </div>
      </section>

      <section id="turnkey" class="video-section">
        <div class="video-frame">
          <iframe src="https://www.youtube-nocookie.com/embed/77hVL7q86zI?rel=0" title="Style Beauty Group 影片" loading="lazy" referrerpolicy="strict-origin-when-cross-origin" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>
        </div>
        <div class="video-copy">
          <p class="eyebrow">{{ copy.approach }}</p>
          <h2 class="multiline-heading">{{ copy.partnerTitle }}</h2>
          <p class="body-copy">{{ copy.partnerBody1 }}</p>
          <p class="body-copy">{{ copy.partnerBody2 }}</p>
          <a class="button button-primary" href="/about">{{ copy.turnkey }} <span aria-hidden="true">↗</span></a>
        </div>
      </section>

      <section id="products" class="products-section section-pad">
        <div class="section-heading products-heading">
          <div>
            <p class="eyebrow">{{ copy.productsEyebrow }}</p>
            <h2>{{ copy.productsTitle }}</h2>
            <p class="products-subtitle">{{ copy.productsSubtitle }}</p>
          </div>
        </div>
        <div class="product-grid">
          <a v-for="product in products" :key="product.name" class="product-feature" :href="product.href">
            <img class="product-feature-image" :src="assetPath(product.image)" :alt="language === 'zh' ? product.zhName : product.name" loading="lazy" />
            <div class="product-feature-shade"></div>
            <div class="product-feature-copy">
              <p class="eyebrow">{{ copy.productsEyebrow }}</p>
              <h3>{{ language === 'zh' ? product.zhName : product.name }}</h3>
              <p>{{ language === 'zh' ? product.zhDescription : product.description }}</p>
              <span class="product-feature-arrow" aria-hidden="true">→</span>
            </div>
          </a>
        </div>
      </section>

      <section id="solutions" class="carousel-section tone-sage" @mouseenter="pauseSolutionsCarousel" @mouseleave="resumeSolutionsAutoplay">
        <div class="carousel-heading">
          <div class="solutions-title"><p class="eyebrow">{{ copy.solutionsEyebrow }}</p><h2>{{ copy.solutionsTitle }}</h2><p class="products-subtitle">{{ copy.solutionsSubtitle }}</p></div>
          <a class="text-link" href="/about">{{ copy.viewSolutions }} <span aria-hidden="true">↗</span></a>
          <div class="carousel-controls">
            <button type="button" aria-label="上一組方案" @click="moveCarousel('solutions', -1)">←</button>
            <button type="button" aria-label="下一組方案" @click="moveCarousel('solutions', 1)">→</button>
          </div>
        </div>
        <div class="solution-viewport" aria-live="polite">
          <div class="solution-track" :style="{ transform: `translateX(-${solutionTrackIndex * 100}%)`, transitionDuration: `${solutionTransitionDuration}ms` }" @transitionend="finishSolutionsTransition">
            <div v-for="(page, trackPageIndex) in solutionTrackPages" :key="page.key" class="solution-slide" :aria-hidden="trackPageIndex !== solutionTrackIndex" :inert="trackPageIndex !== solutionTrackIndex">
              <a v-for="(item, cardIndex) in page.items" :key="`${page.key}-${cardIndex}-${item.name}`" class="solution-card" href="#contact">
                <img class="solution-card-image" :src="`https://images.unsplash.com/${item.image}?auto=format&fit=crop&w=800&q=80`" :alt="language === 'zh' ? item.zhName : item.name" loading="lazy" />
                <span class="solution-card-shade"></span>
                <span class="solution-card-number" aria-hidden="true">{{ String(((page.logicalIndex * solutionPageSize + cardIndex) % solutions.length) + 1).padStart(2, '0') }}</span>
                <span class="solution-card-copy">
                  <span class="solution-card-category">{{ language === 'zh' ? item.zhCategory : item.category }}</span>
                  <span class="solution-card-title">{{ language === 'zh' ? item.zhName : item.name }}</span>
                  <span class="solution-card-arrow" aria-hidden="true">→</span>
                </span>
              </a>
            </div>
          </div>
        </div>
        <div class="carousel-footer"><span>{{ String(solutionIndex + 1).padStart(2, '0') }} <i></i> {{ String(solutionPageCount).padStart(2, '0') }}</span><div class="carousel-dots"><button v-for="(_, index) in solutionPageCount" :key="index" type="button" :class="{ active: index === solutionIndex }" :aria-label="`前往第 ${index + 1} 頁方案`" @click="setSolutionsPage(index)"></button></div></div>
      </section>

      <section id="journal" class="carousel-section tone-rose">
        <div class="carousel-heading">
          <div><p class="eyebrow">{{ copy.inspirationEyebrow }}</p><h2>{{ copy.inspirationTitle }}</h2></div>
          <a class="text-link" href="/video">{{ copy.viewInspiration }} <span aria-hidden="true">↗</span></a>
          <div class="carousel-controls">
            <button type="button" aria-label="上一組靈感" @click="moveCarousel('inspiration', -1)">←</button>
            <button type="button" aria-label="下一組靈感" @click="moveCarousel('inspiration', 1)">→</button>
          </div>
        </div>
        <div class="story-grid">
          <a v-for="item in rotateItems(inspirations, inspirationIndex)" :key="item.name" class="story-card" href="#contact">
            <div class="story-image"><img :src="`https://images.unsplash.com/${item.image}?auto=format&fit=crop&w=800&q=80`" :alt="item.name" loading="lazy" /></div>
            <p class="story-category">{{ language === 'zh' ? item.zhCategory : item.category }}</p><h3>{{ language === 'zh' ? item.zhName : item.name }}</h3>
            <span class="story-link">{{ copy.exploreTrend }} <span aria-hidden="true">↗</span></span>
          </a>
        </div>
        <div class="carousel-footer"><span>0{{ inspirationIndex + 1 }} <i></i> 04</span><div class="carousel-dots"><button v-for="(_, index) in inspirations" :key="index" type="button" :class="{ active: inspirationIndex === index }" :aria-label="`前往第 ${index + 1} 組靈感`" @click="inspirationIndex = index"></button></div></div>
      </section>

      <section id="faq" class="faq-section section-pad">
        <div class="faq-heading"><p class="eyebrow">{{ copy.faqEyebrow }}</p><h2>{{ copy.faqTitle }}</h2><p>{{ copy.faqSubtitle }}</p></div>
        <div class="faq-list">
          <details v-for="(item, index) in questions" :key="item.question" :open="index === 0">
            <summary><span>{{ language === 'zh' ? item.zhQuestion : item.question }}</span><span class="faq-plus" aria-hidden="true"></span></summary>
            <p>{{ language === 'zh' ? item.zhAnswer : item.answer }}</p>
          </details>
        </div>
      </section>
    </main>

    <main v-else-if="currentPageKey === 'beauty-hub'" key="beauty-hub" class="beauty-hub-page">
      <div class="beauty-hub-layout">
        <aside class="beauty-hub-side" :aria-label="language === 'zh' ? '美妝專區導覽' : 'Beauty Hub navigation'">
          <a class="beauty-hub-side-title" href="#beauty-hub-top">BEAUTY HUB</a>
          <div class="beauty-hub-side-tabs" role="tablist" :aria-label="language === 'zh' ? '切換美妝專區內容' : 'Switch Beauty Hub content'">
            <button v-for="section in beautyHubSections" :key="section.id" type="button" role="tab" :class="{ active: beautyHubTab === section.id }" :aria-selected="beautyHubTab === section.id" :aria-controls="`${section.id}-panel`" @click="beautyHubTab = section.id">
              <span><b>{{ section.number }}</b>{{ language === 'zh' ? section.zhEyebrow : section.eyebrow }}</span><i aria-hidden="true"></i>
            </button>
          </div>
        </aside>

        <div class="beauty-hub-content">
          <section v-if="beautyHubTab === 'hub-solutions'" id="beauty-hub-top" class="beauty-hub-hero">
            <img src="/banner2.png" :alt="language === 'zh' ? '彩妝與保養品開發靈感' : 'Beauty product development inspiration'" />
            <div class="beauty-hub-hero-shade"></div>
            <div class="beauty-hub-hero-copy">
              <p class="eyebrow">BEAUTY HUB</p>
              <h1>{{ language === 'zh' ? '美妝產品開發，\n從一個想法開始' : 'Beauty Product Development\nStarts with an Idea' }}</h1>
              <p>{{ language === 'zh' ? '作為 OEM／ODM 開發夥伴，我們協助新創與成熟品牌探索配方、質地、產品表現與包裝方向，從概念到上市，將靈感發展成真正符合市場的美妝產品。' : 'As your OEM/ODM development partner, we help beauty brands navigate formulation, texture, performance and packaging—from first idea to market-ready product.' }}</p>
              <a class="button button-primary" href="#beauty-hub-panel" @click="beautyHubTab = 'hub-solutions'">{{ language === 'zh' ? '探索美妝專區' : 'EXPLORE THE HUB' }} <span aria-hidden="true">→</span></a>
            </div>
            <div class="beauty-hub-hero-note"><strong>PRODUCT SOLUTIONS</strong><span>INSPIRING CONCEPTS</span><span>EXPERT INSIGHTS</span></div>
          </section>

          <section class="beauty-hub-intro">
            <p>{{ language === 'zh' ? '身為 OEM／ODM 產品開發夥伴，我們陪伴品牌探索配方、質地、產品表現與包裝挑戰。從產品概念開始，逐步發展符合品牌與市場需求的完整美妝產品。' : 'As your OEM/ODM development partner, we help emerging and established beauty brands navigate formulation, texture, performance and packaging challenges. Explore new possibilities, refine your product concept, and develop products tailored to your brand and market.' }}</p>
          </section>

          <div id="beauty-hub-panel" class="beauty-hub-panel-shell">
            <Transition name="hub-panel" mode="out-in">
              <section :id="`${activeBeautyHubSection.id}-panel`" :key="activeBeautyHubSection.id" class="beauty-hub-row" :class="{ 'beauty-hub-row--blog': beautyHubTab === 'hub-blog' }" role="tabpanel">
                <template v-if="beautyHubTab === 'hub-blog'">
                  <header class="beauty-hub-blog-heading">
                    <p class="beauty-hub-row-label"><b>{{ activeBeautyHubSection.number }}</b><span>{{ language === 'zh' ? activeBeautyHubSection.zhEyebrow : activeBeautyHubSection.eyebrow }}</span></p>
                    <div><h2>{{ language === 'zh' ? activeBeautyHubSection.zhTitle : activeBeautyHubSection.title }}</h2><p>{{ language === 'zh' ? activeBeautyHubSection.zhDescription : activeBeautyHubSection.description }}</p></div>
                  </header>
                  <div class="beauty-hub-blog-layout">
                    <article class="beauty-hub-blog-feature">
                      <img :src="assetPath(activeBeautyHubSection.items[0].image)" alt="" loading="lazy" />
                      <div class="beauty-hub-blog-feature-copy">
                        <p class="beauty-hub-blog-meta"><span>{{ language === 'zh' ? activeBeautyHubSection.items[0].zhCategory : activeBeautyHubSection.items[0].category }}</span><time>{{ activeBeautyHubSection.items[0].date }}</time></p>
                        <h2>{{ language === 'zh' ? activeBeautyHubSection.items[0].zhName : activeBeautyHubSection.items[0].name }}</h2>
                        <p>{{ language === 'zh' ? activeBeautyHubSection.items[0].zhDetail : activeBeautyHubSection.items[0].detail }}</p>
                        <span class="beauty-hub-blog-read">{{ language === 'zh' ? '閱讀文章' : 'READ ARTICLE' }} <i aria-hidden="true">→</i></span>
                      </div>
                    </article>
                    <div class="beauty-hub-blog-list">
                      <article v-for="item in activeBeautyHubSection.items.slice(1)" :key="item.name">
                        <img :src="assetPath(item.image)" alt="" loading="lazy" />
                        <div><p class="beauty-hub-blog-meta"><span>{{ language === 'zh' ? item.zhCategory : item.category }}</span><time>{{ item.date }}</time></p><h3>{{ language === 'zh' ? item.zhName : item.name }}</h3><p>{{ language === 'zh' ? item.zhDetail : item.detail }}</p><span class="beauty-hub-blog-read">{{ language === 'zh' ? '閱讀文章' : 'READ ARTICLE' }} <i aria-hidden="true">→</i></span></div>
                      </article>
                    </div>
                  </div>
                </template>
                <template v-else>
                  <div class="beauty-hub-row-copy">
                    <p class="beauty-hub-row-label"><b>{{ activeBeautyHubSection.number }}</b><span>{{ language === 'zh' ? activeBeautyHubSection.zhEyebrow : activeBeautyHubSection.eyebrow }}</span></p>
                    <h2>{{ language === 'zh' ? activeBeautyHubSection.zhTitle : activeBeautyHubSection.title }}</h2>
                    <p>{{ language === 'zh' ? activeBeautyHubSection.zhDescription : activeBeautyHubSection.description }}</p>
                    <a href="/contact">{{ language === 'zh' ? '了解更多' : 'View more' }} <span aria-hidden="true">→</span></a>
                  </div>
                  <div class="beauty-hub-card-strip">
                    <article v-for="item in activeBeautyHubSection.items" :key="item.name" class="beauty-hub-card">
                      <img :src="assetPath(item.image)" alt="" loading="lazy" />
                      <h3>{{ language === 'zh' ? item.zhName : item.name }}</h3>
                      <p>{{ language === 'zh' ? item.zhDetail : item.detail }}</p>
                    </article>
                  </div>
                </template>
              </section>
            </Transition>
          </div>

          <Transition name="hub-panel" mode="out-in">
            <div v-if="beautyHubTab === 'hub-solutions'" key="solutions-support" class="beauty-hub-solution-support">
              <section class="beauty-hub-process">
                <div class="beauty-hub-process-copy">
                  <p class="eyebrow">TURNKEY SOLUTION</p>
                  <h2>{{ language === 'zh' ? '從產品方案到市場' : 'From Solution to Market' }}</h2>
                  <p>{{ language === 'zh' ? '依品牌需求選擇產品方向，從配方打樣、包裝確認到量產與交付，建立完整的 OEM／ODM 開發流程。' : 'Choose the right product direction, then move through sampling, packaging, production and delivery with one development partner.' }}</p>
                  <a class="button button-primary" href="/contact">{{ language === 'zh' ? '洽談產品方案' : 'DISCUSS A SOLUTION' }} <span aria-hidden="true">→</span></a>
                </div>
                <div class="beauty-hub-process-line">
                  <article v-for="step in makeupProcess" :key="step.number">
                    <span>{{ step.number }}</span>
                    <img :src="assetPath(step.image)" alt="" loading="lazy" />
                    <h3>{{ language === 'zh' ? step.zhName : step.name }}</h3>
                  </article>
                </div>
              </section>

              <section class="beauty-hub-faq">
                <div class="beauty-hub-faq-heading"><p class="eyebrow">PRODUCT DEVELOPMENT SUPPORT</p><h2>{{ language === 'zh' ? '產品方案常見問題' : 'Product Solution FAQs' }}</h2><p>{{ language === 'zh' ? '了解起訂量、配方開發、包裝、時程與不同市場的產品支援。' : 'Answers about MOQ, formulation, packaging, timelines and market support.' }}</p></div>
                <div class="faq-list">
                  <details v-for="(item, index) in questions" :key="item.question" :open="index === 0">
                    <summary><span><b>{{ String(index + 1).padStart(2, '0') }}</b>{{ language === 'zh' ? item.zhQuestion : item.question }}</span><span class="faq-plus" aria-hidden="true"></span></summary>
                    <p>{{ language === 'zh' ? item.zhAnswer : item.answer }}</p>
                  </details>
                </div>
              </section>
            </div>

            <section v-else-if="beautyHubTab === 'hub-inspirations'" key="inspiration-support" class="beauty-hub-topic-detail beauty-hub-topic-detail--inspiration">
              <div class="beauty-hub-topic-heading"><p class="eyebrow">FROM TREND TO CONCEPT</p><h2>{{ language === 'zh' ? '把趨勢靈感轉化為產品概念' : 'Turn Trends into Product Concepts' }}</h2><p>{{ language === 'zh' ? '從市場訊號、消費者情境到配方與包裝方向，逐步建立可被開發與驗證的產品提案。' : 'Move from market signals and consumer needs to a focused formula, format and packaging concept.' }}</p></div>
              <div class="beauty-hub-topic-grid">
                <article><span>01</span><h3>{{ language === 'zh' ? '觀察市場訊號' : 'Read Market Signals' }}</h3><p>{{ language === 'zh' ? '整理色彩、質地、成分與生活風格趨勢。' : 'Track shifts in color, texture, ingredients and lifestyle.' }}</p></article>
                <article><span>02</span><h3>{{ language === 'zh' ? '描繪使用情境' : 'Define the Moment' }}</h3><p>{{ language === 'zh' ? '確認目標消費者、使用時機與核心需求。' : 'Clarify the audience, use occasion and key need.' }}</p></article>
                <article><span>03</span><h3>{{ language === 'zh' ? '建立產品概念' : 'Shape the Concept' }}</h3><p>{{ language === 'zh' ? '整合產品形式、訴求、感官體驗與品牌語言。' : 'Connect format, benefit, sensory feel and brand story.' }}</p></article>
                <article><span>04</span><h3>{{ language === 'zh' ? '驗證開發方向' : 'Validate Direction' }}</h3><p>{{ language === 'zh' ? '透過打樣與討論，收斂成可執行的產品提案。' : 'Use sampling and review to refine a workable brief.' }}</p></article>
              </div>
              <a class="button button-primary" href="/contact">{{ language === 'zh' ? '討論產品靈感' : 'DISCUSS AN IDEA' }} <span aria-hidden="true">→</span></a>
            </section>

            <section v-else key="blog-support" class="beauty-hub-topic-detail beauty-hub-topic-detail--blog">
              <div class="beauty-hub-topic-heading"><p class="eyebrow">EXPERT KNOWLEDGE</p><h2>{{ language === 'zh' ? '從專業內容掌握開發關鍵' : 'Knowledge for Better Product Decisions' }}</h2><p>{{ language === 'zh' ? '以市場、配方、包裝與品牌四個面向，整理產品開發過程需要理解的觀點與實務知識。' : 'Explore practical perspectives across market, formulation, packaging and brand development.' }}</p></div>
              <div class="beauty-hub-topic-grid">
                <article><span>01</span><h3>{{ language === 'zh' ? '市場觀察' : 'Market Intelligence' }}</h3><p>{{ language === 'zh' ? '解析消費趨勢、品類機會與市場需求。' : 'Consumer shifts, category opportunities and market needs.' }}</p></article>
                <article><span>02</span><h3>{{ language === 'zh' ? '配方筆記' : 'Formula Notes' }}</h3><p>{{ language === 'zh' ? '理解質地、成分選擇與產品表現之間的關係。' : 'How texture, ingredients and performance work together.' }}</p></article>
                <article><span>03</span><h3>{{ language === 'zh' ? '包裝指南' : 'Packaging Guide' }}</h3><p>{{ language === 'zh' ? '掌握容器選擇、設計溝通與量產注意事項。' : 'Component choices, artwork coordination and production details.' }}</p></article>
                <article><span>04</span><h3>{{ language === 'zh' ? '品牌成長' : 'Brand Growth' }}</h3><p>{{ language === 'zh' ? '從產品組合到上市節奏，建立清晰品牌方向。' : 'Build a clear portfolio and a considered launch path.' }}</p></article>
              </div>
              <a class="button button-primary" href="/contact">{{ language === 'zh' ? '詢問專業建議' : 'ASK OUR TEAM' }} <span aria-hidden="true">→</span></a>
            </section>
          </Transition>
        </div>
      </div>
    </main>

    <main v-else-if="currentPageKey === 'about'" key="about" class="about-landing">
      <section class="about-hero">
        <img src="/banner2.png" :alt="language === 'zh' ? 'Style Beauty Group 彩妝與保養產品' : 'Style Beauty Group makeup and skincare products'" />
        <div class="about-hero-shade"></div>
        <div class="about-hero-copy">
          <p class="about-breadcrumb">{{ language === 'zh' ? '首頁　›　關於我們' : 'Home　›　About' }}</p>
          <p class="eyebrow">ABOUT US</p>
          <h1>{{ language === 'zh' ? '超越製造，\n我們實現美妝創意' : 'Beyond Manufacturing,\nWe Build Beauty Ideas.' }}</h1>
        </div>
      </section>

      <section class="about-company">
        <div class="about-company-copy">
          <p class="eyebrow">WHO WE ARE</p>
          <h2>{{ language === 'zh' ? '我們傾聽需求，\n也實現每一個想法。' : 'We can meet and\nsatisfy your requirements.' }}</h2>
          <p>{{ language === 'zh' ? '累積超過 40 年的美妝產業經驗，STYLE BEAUTY GROUP 是台灣專業的彩妝與保養品製造夥伴。我們提供 OEM、ODM 與自有品牌的一站式服務，從產品概念、配方、質地、包裝到量產，陪伴品牌將創意轉化為具市場競爭力的產品。' : 'With over 40 years of industry expertise, STYLE BEAUTY GROUP is a leading makeup and skincare manufacturing company in Taiwan, specializing in high-quality OEM cosmetics and full-service solutions.' }}</p>
          <p>{{ language === 'zh' ? '我們的團隊結合研發、包裝設計與製造能力，重視每位客戶的長期目標，協助新創與成熟品牌建立完整產品線，並拓展國際市場。' : 'Our one-stop OEM and ODM services cover product formulation, packaging design and mass production. We value our clients as long-term partners and help brands turn their vision into reality.' }}</p>
        </div>
        <figure class="about-building"><img src="https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1200&q=85" :alt="language === 'zh' ? 'Style Beauty Group 企業與製造據點意象' : 'Style Beauty Group company and manufacturing facility'" /><figcaption>TAICHUNG · TAIWAN</figcaption></figure>
      </section>

      <section class="about-story">
        <figure><img src="/banner%20p%20.png" :alt="language === 'zh' ? '美妝配方與質地' : 'Beauty formulas and textures'" /></figure>
        <div><p class="eyebrow">OUR STORY</p><h2>{{ language === 'zh' ? '把想法，變成令人喜愛的美妝產品。' : 'Turning Ideas into Beauty Products' }}</h2><p>{{ language === 'zh' ? '每一項產品都從不同的需求開始：可能是一個概念、一種質地、一個性能目標，或一道需要被解決的市場挑戰。' : 'Every beauty product starts differently—a concept, a texture, a performance target, or simply a challenge that needs solving.' }}</p><p>{{ language === 'zh' ? '作為台灣美妝 OEM／ODM 製造商，我們協助品牌從配方、色彩開發、包裝、測試到製造，一步步建立可以上市的完整產品。' : 'As a Taiwan-based cosmetics OEM/ODM manufacturer, we help turn starting points into products ready for production.' }}</p></div>
      </section>

      <section class="about-expertise">
        <img src="/banner.png" alt="" />
        <div class="about-expertise-shade"></div>
        <div class="about-expertise-copy"><p class="eyebrow">OUR EXPERTISE</p><h2>{{ language === 'zh' ? '從配方到量產，完整實現產品藍圖。' : 'Expertise from formula to finished product' }}</h2><p>{{ language === 'zh' ? '從配方開發、質地、色彩與包裝，到品牌在意的產品宣稱與市場需求，我們以完整服務串連每一個開發環節。' : 'From formula development to texture, color and packaging, we help brands shape products into consistent cosmetic solutions.' }}</p><p>{{ language === 'zh' ? '一站式流程涵蓋開發、測試、包材、量產與交付，讓品牌可以更專注於市場與長期成長。' : 'Our turnkey process guides every stage from development and testing to packaging, production and delivery.' }}</p><a class="button button-primary" href="/contact">{{ language === 'zh' ? '洽談合作計畫' : 'DISCUSS YOUR PROJECT' }} <span aria-hidden="true">→</span></a></div>
      </section>

      <section class="about-pillars">
        <article><i aria-hidden="true">◇</i><h3>{{ language === 'zh' ? '專業經驗' : 'Expertise' }}</h3><p>{{ language === 'zh' ? '超過 40 年彩妝與保養品製造經驗。' : 'Over 40 years of experience in cosmetics development and manufacturing.' }}</p></article>
        <article><i aria-hidden="true">⌬</i><h3>{{ language === 'zh' ? '創新研發' : 'Innovation' }}</h3><p>{{ language === 'zh' ? '將創意與市場洞察轉化為高品質產品。' : 'Turning ideas and market insights into unique products.' }}</p></article>
        <article><i aria-hidden="true">◎</i><h3>{{ language === 'zh' ? '合作夥伴' : 'Partnership' }}</h3><p>{{ language === 'zh' ? '陪伴不同規模品牌建立客製解決方案。' : 'Supporting brands of all sizes with flexible solutions.' }}</p></article>
        <article><i aria-hidden="true">⊕</i><h3>{{ language === 'zh' ? '全球視野' : 'Global Perspective' }}</h3><p>{{ language === 'zh' ? '與國際品牌合作，打造符合市場需求的產品。' : 'Working with beauty brands worldwide to create market-ready products.' }}</p></article>
      </section>

      <section class="about-why"><div><p class="eyebrow">OUR APPROACH</p><h2>{{ language === 'zh' ? '為什麼美妝品牌選擇與我們合作' : 'Why Beauty Brands Work With Us' }}</h2></div><p>{{ language === 'zh' ? '我們協助品牌把起點轉化為準備量產的完整產品，從產品策略、配方、色號開發、包裝、測試到製造，以清楚的流程、穩定的溝通與長期合作推動每個專案。' : 'As a Taiwan-based cosmetics OEM/ODM manufacturer, we help turn starting points into products ready for production, supporting brands through formulation, shade development, packaging, testing and manufacturing.' }}</p></section>
    </main>

    <main v-else-if="currentPageKey === 'sun-care'" key="sun-care" class="sun-landing">
      <section class="sun-hero">
        <img src="/images/sun-care-hero.png" :alt="language === 'zh' ? '陽光下的防曬產品與海岸風景' : 'Sun care products on a sunlit coastal terrace'" />
        <div class="sun-hero-glow"></div>
        <div class="sun-hero-copy">
          <p class="eyebrow">SUN CARE · OEM / ODM</p>
          <h1>{{ language === 'zh' ? '讓陽光停在肌膚之外' : 'Made for Life in the Sun' }}</h1>
          <p>{{ language === 'zh' ? '從清透日常防護到戶外高效需求，打造膚感舒適、符合品牌定位的客製防曬產品。' : 'From weightless daily protection to high-performance outdoor care, we create sun care designed around your brand.' }}</p>
          <a class="button button-primary" href="/contact">{{ language === 'zh' ? '開始防曬產品計畫' : 'START YOUR SUN CARE PROJECT' }} <span aria-hidden="true">→</span></a>
        </div>
        <div class="sun-hero-caption"><span>WARM LIGHT</span><i></i><span>BARELY-THERE FEEL</span></div>
      </section>

      <section class="sun-catalog">
        <div class="sun-catalog-heading">
          <div><p class="eyebrow">EXPLORE BY CATEGORY</p><h2>{{ language === 'zh' ? '探索防曬產品解決方案' : 'Discover Our Sun Care Solutions' }}</h2></div>
          <p>{{ language === 'zh' ? '從日常臉部防護到戶外高效使用，依品牌市場與產品定位，發展適合的防曬形式與質地。' : 'Explore sun care formats and textures designed around your brand, market and everyday protection needs.' }}</p>
        </div>
        <div class="sun-catalog-grid">
          <article><img src="/images/sun-care-hero.png" alt="" /><span>01</span><h3>{{ language === 'zh' ? '臉部防曬乳' : 'Face Sunscreen' }}</h3></article>
          <article><img src="/images/makeup/textures/foundation.png" alt="" /><span>02</span><h3>{{ language === 'zh' ? '清爽防曬凝乳' : 'Sun Gel Cream' }}</h3></article>
          <article><img src="https://images.unsplash.com/photo-1556229010-6c3f2c9ca5f8?auto=format&fit=crop&w=700&q=82" alt="" /><span>03</span><h3>{{ language === 'zh' ? '高效戶外防曬' : 'Outdoor Protection' }}</h3></article>
          <article><img src="https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&w=700&q=82" alt="" /><span>04</span><h3>{{ language === 'zh' ? '防曬噴霧' : 'Sun Mist & Spray' }}</h3></article>
          <article><img src="/images/makeup/textures/cream-blush.png" alt="" /><span>05</span><h3>{{ language === 'zh' ? '潤色防曬' : 'Tone-Up Sunscreen' }}</h3></article>
          <article><img src="/images/makeup/textures/gel.png" alt="" /><span>06</span><h3>{{ language === 'zh' ? '礦物防曬' : 'Mineral Sunscreen' }}</h3></article>
          <article><img src="/images/makeup/textures/highlighter.png" alt="" /><span>07</span><h3>{{ language === 'zh' ? '精華型防曬' : 'Sun Serum' }}</h3></article>
          <article><img src="/banner%20p%20.png" alt="" /><span>08</span><h3>{{ language === 'zh' ? '身體防曬' : 'Body Sun Care' }}</h3></article>
          <article><img src="/images/makeup/textures/lip-glaze.png" alt="" /><span>09</span><h3>{{ language === 'zh' ? '妝前防曬' : 'Sun Primer' }}</h3></article>
          <article><img src="https://images.unsplash.com/photo-1611930022073-b7a4ba5fcccd?auto=format&fit=crop&w=700&q=82" alt="" /><span>10</span><h3>{{ language === 'zh' ? '曬後舒緩' : 'After-Sun Care' }}</h3></article>
        </div>
      </section>

      <section class="sun-goals">
        <div class="sun-goals-heading"><h2>{{ language === 'zh' ? '依需求與產品目標開發' : 'Develop by Sun Care Goals' }}</h2><p>{{ language === 'zh' ? '聚焦消費者在陽光下的真實使用感受。' : 'Built around real life in the sun.' }}</p></div>
        <div class="sun-goals-grid">
          <article><img src="/images/makeup/textures/gel.png" alt="" /><h3>{{ language === 'zh' ? '清爽不黏膩' : 'Weightless Feel' }}</h3><p>{{ language === 'zh' ? '輕盈、好延展的日常膚感。' : 'Fresh, easy-spreading daily textures.' }}</p></article>
          <article><img src="/images/makeup/textures/highlighter.png" alt="" /><h3>{{ language === 'zh' ? '保濕與光澤' : 'Hydration & Glow' }}</h3><p>{{ language === 'zh' ? '兼顧潤澤度與自然光感。' : 'Comfortable moisture with natural radiance.' }}</p></article>
          <article><img src="https://images.unsplash.com/photo-1556228578-0d85b1a4d571?auto=format&fit=crop&w=600&q=80" alt="" /><h3>{{ language === 'zh' ? '戶外高效防護' : 'Outdoor Performance' }}</h3><p>{{ language === 'zh' ? '為長時間日照情境規劃。' : 'Developed for extended sun exposure.' }}</p></article>
          <article><img src="/images/makeup/textures/foundation.png" alt="" /><h3>{{ language === 'zh' ? '敏弱肌膚感' : 'Gentle Skin Feel' }}</h3><p>{{ language === 'zh' ? '以舒適、溫和的使用感為核心。' : 'Comfort-first sensorial development.' }}</p></article>
          <article><img src="/images/makeup/textures/cream-blush.png" alt="" /><h3>{{ language === 'zh' ? '潤色與妝前' : 'Tone-Up & Primer' }}</h3><p>{{ language === 'zh' ? '自然修飾並銜接後續底妝。' : 'Natural correction designed under makeup.' }}</p></article>
          <article><img src="/images/makeup/textures/lip-glaze.png" alt="" /><h3>{{ language === 'zh' ? '防曬保養融合' : 'Skincare Hybrid' }}</h3><p>{{ language === 'zh' ? '結合日常保養概念與防護。' : 'Protection paired with skincare benefits.' }}</p></article>
        </div>
      </section>

      <section class="sun-turnkey">
        <div class="sun-turnkey-heading"><p class="eyebrow">TURNKEY SOLUTION</p><h2>{{ language === 'zh' ? '一站式防曬產品開發' : 'Turnkey Sun Care Development' }}</h2></div>
        <div class="sun-turnkey-line">
          <article><span>01</span><div class="sun-turnkey-icon">☼</div><h3>{{ language === 'zh' ? '產品定位' : 'Product Brief' }}</h3></article>
          <article><span>02</span><div class="sun-turnkey-icon">⌁</div><h3>{{ language === 'zh' ? '配方打樣' : 'Sampling' }}</h3></article>
          <article><span>03</span><div class="sun-turnkey-icon">✓</div><h3>{{ language === 'zh' ? '樣品確認' : 'Confirmation' }}</h3></article>
          <article><span>04</span><div class="sun-turnkey-icon">▤</div><h3>{{ language === 'zh' ? '報價' : 'Quotation' }}</h3></article>
          <article><span>05</span><div class="sun-turnkey-icon">◇</div><h3>{{ language === 'zh' ? '包裝設計' : 'Packaging' }}</h3></article>
          <article><span>06</span><div class="sun-turnkey-icon">▥</div><h3>{{ language === 'zh' ? '正式量產' : 'Production' }}</h3></article>
          <article><span>07</span><div class="sun-turnkey-icon">□</div><h3>{{ language === 'zh' ? '出貨交付' : 'Delivery' }}</h3></article>
          <article><span>08</span><div class="sun-turnkey-icon">◎</div><h3>{{ language === 'zh' ? '售後支援' : 'Support' }}</h3></article>
        </div>
      </section>
    </main>

    <main v-else-if="currentPageKey === 'skincare'" key="skincare" class="sun-landing skincare-landing">
      <section class="sun-hero">
        <img src="https://images.unsplash.com/photo-1611930022073-b7a4ba5fcccd?auto=format&fit=crop&w=2000&q=88" :alt="language === 'zh' ? '自然光下的保養品與精華產品' : 'Skincare and serum products in natural light'" />
        <div class="sun-hero-glow"></div>
        <div class="sun-hero-copy">
          <p class="eyebrow">SKINCARE · OEM / ODM</p>
          <h1>{{ language === 'zh' ? '讓保養成為肌膚的日常力量' : 'Skincare Made for Everyday Rituals' }}</h1>
          <p>{{ language === 'zh' ? '從配方質地、活性概念到包裝量產，打造符合品牌定位與市場需求的客製保養品。' : 'From formula and texture to packaging and production, we create skincare shaped around your brand and market.' }}</p>
          <a class="button button-primary" href="/contact">{{ language === 'zh' ? '開始保養品計畫' : 'START YOUR SKINCARE PROJECT' }} <span aria-hidden="true">→</span></a>
        </div>
        <div class="sun-hero-caption"><span>THOUGHTFUL FORMULAS</span><i></i><span>DAILY CARE</span></div>
      </section>

      <section class="sun-catalog">
        <div class="sun-catalog-heading">
          <div><p class="eyebrow">EXPLORE BY CATEGORY</p><h2>{{ language === 'zh' ? '探索保養品解決方案' : 'Discover Our Skincare Solutions' }}</h2></div>
          <p>{{ language === 'zh' ? '多元配方與質地選擇，從日常清潔到密集修護，發展符合品牌市場的完整保養系列。' : 'Explore skincare formats and textures from daily cleansing to intensive care, developed around your brand.' }}</p>
        </div>
        <div class="sun-catalog-grid">
          <article><img src="https://images.unsplash.com/photo-1556229010-6c3f2c9ca5f8?auto=format&fit=crop&w=700&q=82" alt="" /><span>01</span><h3>{{ language === 'zh' ? '潔面產品' : 'Cleansers' }}</h3></article>
          <article><img src="https://images.unsplash.com/photo-1601049541289-9b1b7bbbfe19?auto=format&fit=crop&w=700&q=82" alt="" /><span>02</span><h3>{{ language === 'zh' ? '化妝水' : 'Toners' }}</h3></article>
          <article><img src="https://images.unsplash.com/photo-1556228578-0d85b1a4d571?auto=format&fit=crop&w=700&q=82" alt="" /><span>03</span><h3>{{ language === 'zh' ? '精華液與精華露' : 'Serums & Essences' }}</h3></article>
          <article><img src="https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&w=700&q=82" alt="" /><span>04</span><h3>{{ language === 'zh' ? '噴霧與保濕水' : 'Spray & Mist' }}</h3></article>
          <article><img src="https://images.unsplash.com/photo-1611930022073-b7a4ba5fcccd?auto=format&fit=crop&w=700&q=82" alt="" /><span>05</span><h3>{{ language === 'zh' ? '乳霜與保濕產品' : 'Creams & Moisturizers' }}</h3></article>
          <article><img src="/images/makeup/textures/gel.png" alt="" /><span>06</span><h3>{{ language === 'zh' ? '面膜' : 'Masks' }}</h3></article>
          <article><img src="/images/makeup/textures/highlighter.png" alt="" /><span>07</span><h3>{{ language === 'zh' ? '特殊保養' : 'Specialized Skincare' }}</h3></article>
          <article><img src="/banner%20p%20.png" alt="" /><span>08</span><h3>{{ language === 'zh' ? '身體保養' : 'Body Care' }}</h3></article>
          <article><img src="/images/makeup/textures/lip-glaze.png" alt="" /><span>09</span><h3>{{ language === 'zh' ? '安瓶' : 'Ampoule' }}</h3></article>
          <article><img src="/banner2.png" alt="" /><span>10</span><h3>{{ language === 'zh' ? '男士理容' : "Men's Grooming" }}</h3></article>
        </div>
      </section>

      <section class="sun-goals">
        <div class="sun-goals-heading"><h2>{{ language === 'zh' ? '依肌膚需求與產品目標開發' : 'Develop by Skin Concern & Product Goals' }}</h2><p>{{ language === 'zh' ? '從日常膚況出發，建立清晰的產品訴求。' : 'Built around real skin needs and clear product goals.' }}</p></div>
        <div class="sun-goals-grid">
          <article><img src="/images/makeup/textures/gel.png" alt="" /><h3>{{ language === 'zh' ? '補水與保濕' : 'Hydration & Moisture' }}</h3><p>{{ language === 'zh' ? '維持柔嫩、舒適的肌膚感受。' : 'Healthy, moisture-rich skin feel.' }}</p></article>
          <article><img src="/images/makeup/textures/highlighter.png" alt="" /><h3>{{ language === 'zh' ? '亮白與透亮' : 'Brightening & Radiance' }}</h3><p>{{ language === 'zh' ? '打造均勻、明亮的光澤膚況。' : 'Even-looking tone and natural radiance.' }}</p></article>
          <article><img src="https://images.unsplash.com/photo-1556229010-6c3f2c9ca5f8?auto=format&fit=crop&w=600&q=80" alt="" /><h3>{{ language === 'zh' ? '抗老修護' : 'Age Support' }}</h3><p>{{ language === 'zh' ? '回應熟齡肌膚的修護需求。' : 'Care designed for mature skin needs.' }}</p></article>
          <article><img src="/images/makeup/textures/foundation.png" alt="" /><h3>{{ language === 'zh' ? '敏弱肌呵護' : 'Sensitive Skin Care' }}</h3><p>{{ language === 'zh' ? '以溫和舒適的使用感為核心。' : 'Gentle formulas with a comfortable feel.' }}</p></article>
          <article><img src="/images/makeup/textures/cream-blush.png" alt="" /><h3>{{ language === 'zh' ? '痘肌與控油' : 'Acne & Oil Control' }}</h3><p>{{ language === 'zh' ? '協助維持清爽與油水平衡。' : 'Fresh textures for balanced-looking skin.' }}</p></article>
          <article><img src="/images/makeup/textures/lip-glaze.png" alt="" /><h3>{{ language === 'zh' ? '妝養合一' : 'Hybrid Skincare' }}</h3><p>{{ language === 'zh' ? '結合保養概念與多效使用體驗。' : 'Skincare benefits in hybrid formats.' }}</p></article>
        </div>
      </section>

      <section class="sun-turnkey">
        <div class="sun-turnkey-heading"><p class="eyebrow">TURNKEY SOLUTION</p><h2>{{ language === 'zh' ? '一站式保養品開發' : 'Turnkey Skincare Development' }}</h2></div>
        <div class="sun-turnkey-line">
          <article><span>01</span><div class="sun-turnkey-icon">◌</div><h3>{{ language === 'zh' ? '產品定位' : 'Product Brief' }}</h3></article>
          <article><span>02</span><div class="sun-turnkey-icon">⌁</div><h3>{{ language === 'zh' ? '配方打樣' : 'Sampling' }}</h3></article>
          <article><span>03</span><div class="sun-turnkey-icon">✓</div><h3>{{ language === 'zh' ? '樣品確認' : 'Confirmation' }}</h3></article>
          <article><span>04</span><div class="sun-turnkey-icon">▤</div><h3>{{ language === 'zh' ? '報價' : 'Quotation' }}</h3></article>
          <article><span>05</span><div class="sun-turnkey-icon">◇</div><h3>{{ language === 'zh' ? '包裝設計' : 'Packaging' }}</h3></article>
          <article><span>06</span><div class="sun-turnkey-icon">▥</div><h3>{{ language === 'zh' ? '正式量產' : 'Production' }}</h3></article>
          <article><span>07</span><div class="sun-turnkey-icon">□</div><h3>{{ language === 'zh' ? '出貨交付' : 'Delivery' }}</h3></article>
          <article><span>08</span><div class="sun-turnkey-icon">◎</div><h3>{{ language === 'zh' ? '售後支援' : 'Support' }}</h3></article>
        </div>
      </section>
    </main>

    <main v-else-if="currentPageKey === 'mens-care'" key="mens-care" class="sun-landing mens-landing">
      <section class="sun-hero">
        <img src="/images/mens-care-hero.png" :alt="language === 'zh' ? '暖陽下的男士理容與保養產品' : 'Men grooming and skincare products in warm sunlight'" />
        <div class="sun-hero-glow"></div>
        <div class="sun-hero-copy">
          <p class="eyebrow">MEN'S CARE · OEM / ODM</p>
          <h1>{{ language === 'zh' ? '簡潔保養，為現代生活而生' : 'Modern Care. Made Simple.' }}</h1>
          <p>{{ language === 'zh' ? '從日常清潔、刮鬍理容到臉部與身體保養，打造實用、俐落且符合品牌定位的男士產品系列。' : 'From daily cleansing and shaving to face and body care, we create practical grooming products for modern routines.' }}</p>
          <a class="button button-primary" href="/contact">{{ language === 'zh' ? '開始男士保養計畫' : "START YOUR MEN'S CARE PROJECT" }} <span aria-hidden="true">→</span></a>
        </div>
        <div class="sun-hero-caption"><span>MODERN ESSENTIALS</span><i></i><span>DAILY PERFORMANCE</span></div>
      </section>

      <section class="sun-catalog">
        <div class="sun-catalog-heading">
          <div><p class="eyebrow">EXPLORE BY CATEGORY</p><h2>{{ language === 'zh' ? '探索男士保養解決方案' : "Discover Our Men's Care Solutions" }}</h2></div>
          <p>{{ language === 'zh' ? '從臉部清潔、刮鬍理容到身體與髮品，依照使用習慣與品牌市場打造完整系列。' : 'Explore face, shave, body and hair care formats designed around modern routines and your brand.' }}</p>
        </div>
        <div class="sun-catalog-grid">
          <article><img src="/images/mens-care-cleanser.png" alt="" /><span>01</span><h3>{{ language === 'zh' ? '臉部清潔' : 'Face Cleanser' }}</h3></article>
          <article><img src="/images/mens-care-shave.png" alt="" /><span>02</span><h3>{{ language === 'zh' ? '刮鬍產品' : 'Shaving Care' }}</h3></article>
          <article><img src="/images/mens-care-shave.png" alt="" /><span>03</span><h3>{{ language === 'zh' ? '鬍後舒緩' : 'After-Shave Care' }}</h3></article>
          <article><img src="/images/mens-care-serum.png" alt="" /><span>04</span><h3>{{ language === 'zh' ? '臉部保濕' : 'Face Moisturizer' }}</h3></article>
          <article><img src="/images/mens-care-serum.png" alt="" /><span>05</span><h3>{{ language === 'zh' ? '精華液' : 'Face Serum' }}</h3></article>
          <article><img src="/images/mens-care-serum.png" alt="" /><span>06</span><h3>{{ language === 'zh' ? '眼部保養' : 'Eye Care' }}</h3></article>
          <article><img src="/images/mens-care-body.png" alt="" /><span>07</span><h3>{{ language === 'zh' ? '鬍鬚保養' : 'Beard Care' }}</h3></article>
          <article><img src="/images/mens-care-body.png" alt="" /><span>08</span><h3>{{ language === 'zh' ? '身體清潔與保養' : 'Body Care' }}</h3></article>
          <article><img src="/images/mens-care-body.png" alt="" /><span>09</span><h3>{{ language === 'zh' ? '髮品與頭皮護理' : 'Hair & Scalp Care' }}</h3></article>
          <article><img src="/images/mens-care-cleanser.png" alt="" /><span>10</span><h3>{{ language === 'zh' ? '體香與日常理容' : 'Deodorant & Grooming' }}</h3></article>
        </div>
      </section>

      <section class="sun-goals">
        <div class="sun-goals-heading"><h2>{{ language === 'zh' ? '依男士需求與生活方式開發' : "Develop by Men's Needs & Lifestyle" }}</h2><p>{{ language === 'zh' ? '以效率、膚感與日常表現為核心。' : 'Built around efficiency, feel and daily performance.' }}</p></div>
        <div class="sun-goals-grid">
          <article><img src="/images/mens-care-cleanser.png" alt="" /><h3>{{ language === 'zh' ? '清爽控油' : 'Oil Control' }}</h3><p>{{ language === 'zh' ? '維持潔淨、清爽的使用感。' : 'Fresh textures for balanced-looking skin.' }}</p></article>
          <article><img src="/images/mens-care-serum.png" alt="" /><h3>{{ language === 'zh' ? '補水保濕' : 'Hydration' }}</h3><p>{{ language === 'zh' ? '舒適潤澤而不感厚重。' : 'Comfortable moisture without heaviness.' }}</p></article>
          <article><img src="/images/mens-care-shave.png" alt="" /><h3>{{ language === 'zh' ? '刮鬍舒緩' : 'Shave Recovery' }}</h3><p>{{ language === 'zh' ? '回應刮鬍後的肌膚感受。' : 'Comfort-focused post-shave care.' }}</p></article>
          <article><img src="/images/mens-care-serum.png" alt="" /><h3>{{ language === 'zh' ? '熟齡修護' : 'Age Support' }}</h3><p>{{ language === 'zh' ? '針對乾燥與成熟膚況設計。' : 'Care for dry and mature-looking skin.' }}</p></article>
          <article><img src="/images/mens-care-body.png" alt="" /><h3>{{ language === 'zh' ? '活力醒膚' : 'Energizing Care' }}</h3><p>{{ language === 'zh' ? '打造明亮、有精神的外觀。' : 'Fresh care for an energized appearance.' }}</p></article>
          <article><img src="/images/mens-care-cleanser.png" alt="" /><h3>{{ language === 'zh' ? '多效合一' : 'Multi-Use Essentials' }}</h3><p>{{ language === 'zh' ? '簡化步驟，滿足多重日常需求。' : 'Streamlined formats for simple routines.' }}</p></article>
        </div>
      </section>

      <section class="sun-turnkey">
        <div class="sun-turnkey-heading"><p class="eyebrow">TURNKEY SOLUTION</p><h2>{{ language === 'zh' ? '一站式男士保養開發' : "Turnkey Men's Care Development" }}</h2></div>
        <div class="sun-turnkey-line">
          <article><span>01</span><div class="sun-turnkey-icon">◼</div><h3>{{ language === 'zh' ? '產品定位' : 'Product Brief' }}</h3></article>
          <article><span>02</span><div class="sun-turnkey-icon">⌁</div><h3>{{ language === 'zh' ? '配方打樣' : 'Sampling' }}</h3></article>
          <article><span>03</span><div class="sun-turnkey-icon">✓</div><h3>{{ language === 'zh' ? '樣品確認' : 'Confirmation' }}</h3></article>
          <article><span>04</span><div class="sun-turnkey-icon">▤</div><h3>{{ language === 'zh' ? '報價' : 'Quotation' }}</h3></article>
          <article><span>05</span><div class="sun-turnkey-icon">◇</div><h3>{{ language === 'zh' ? '包裝設計' : 'Packaging' }}</h3></article>
          <article><span>06</span><div class="sun-turnkey-icon">▥</div><h3>{{ language === 'zh' ? '正式量產' : 'Production' }}</h3></article>
          <article><span>07</span><div class="sun-turnkey-icon">□</div><h3>{{ language === 'zh' ? '出貨交付' : 'Delivery' }}</h3></article>
          <article><span>08</span><div class="sun-turnkey-icon">◎</div><h3>{{ language === 'zh' ? '售後支援' : 'Support' }}</h3></article>
        </div>
      </section>
    </main>

    <main v-else-if="currentPageKey === 'makeup'" key="makeup" class="makeup-page">
      <div class="makeup-catalog-shell">
        <aside class="makeup-side-nav" :aria-label="language === 'zh' ? '彩妝品類導覽' : 'Makeup category navigation'">
          <strong>{{ language === 'zh' ? '彩妝' : 'Makeup' }}</strong>
          <div v-for="category in makeupCategories" :key="category.name" class="makeup-side-group" :class="{ 'is-expanded': expandedMakeupCategory === category.name }">
            <div class="makeup-side-row">
              <a class="makeup-side-category-link" :href="`/makeup/${category.slug}`">{{ language === 'zh' ? category.zhName : category.name }}</a>
              <button class="makeup-side-toggle" type="button" :aria-expanded="expandedMakeupCategory === category.name" :aria-controls="`makeup-side-${category.slug}`" @click="toggleMakeupCategory(category.name)">
                <span class="makeup-side-more">{{ expandedMakeupCategory === category.name ? 'CLOSE' : 'MORE' }}</span>
              </button>
            </div>
            <div v-show="expandedMakeupCategory === category.name" :id="`makeup-side-${category.slug}`" class="makeup-side-submenu">
              <a v-for="(item, index) in category.items" :key="item" :href="`/makeup/${category.slug}/${category.itemSlugs[index]}`">
                <span>{{ language === 'zh' ? category.zhItems[index] : item }}</span><span aria-hidden="true">→</span>
              </a>
            </div>
          </div>
        </aside>

        <div class="makeup-catalog-main">
          <section class="makeup-hero">
            <img src="/images/makeup/hero.png" :alt="language === 'zh' ? '裸粉與玫瑰金色調的彩妝產品與質地' : 'Nude pink and rose-gold makeup products and textures'" />
            <div class="makeup-hero-shade"></div>
            <div class="makeup-hero-copy">
              <nav class="makeup-breadcrumb" aria-label="Breadcrumb"><a href="/">{{ language === 'zh' ? '首頁' : 'Home' }}</a><span>›</span><span>{{ language === 'zh' ? '彩妝' : 'Makeup' }}</span></nav>
              <h1>{{ language === 'zh' ? '彩妝' : 'Makeup' }}</h1>
              <p class="makeup-tagline">{{ language === 'zh' ? '色彩．質地．妝效' : 'Color. Texture. Performance.' }}</p>
              <p>{{ language === 'zh' ? '為你的品牌，創造專屬妝感。' : 'Made for Your Brand.' }}</p>
              <small>{{ language === 'zh' ? '從潮流色彩、創新質地到多元包裝，提供完整彩妝客製開發服務。' : 'From trend-driven color to innovative textures, we create customized makeup solutions for your brand.' }}</small>
              <a class="button button-primary" href="/contact">{{ language === 'zh' ? '立即洽詢' : 'INQUIRE NOW' }} <span aria-hidden="true">→</span></a>
            </div>
          </section>

          <section class="makeup-intro">
            <p class="eyebrow">{{ language === 'zh' ? '探索自有品牌彩妝產品' : 'EXPLORE OUR PRIVATE LABEL MAKEUP PRODUCTS' }}</p>
            <h2>{{ language === 'zh' ? '為你的品牌，打造理想彩妝。' : 'Makeup made for your brand.' }}</h2>
            <p>{{ language === 'zh' ? 'Style Beauty Group 提供完整的自有品牌彩妝開發服務，融合趨勢色彩、細緻質地與穩定妝效。從配方、色號、包裝到量產，我們以 OEM／ODM 經驗協助品牌打造具有市場辨識度的彩妝產品。' : 'At STYLE BEAUTY GROUP, we offer a wide range of private label makeup products that combine trend-forward design with proven performance. From formula and shade development to packaging and production, we support every step.' }}</p>
          </section>

          <section id="makeup-categories" class="makeup-categories">
            <div class="makeup-section-heading">
              <p class="eyebrow">{{ language === 'zh' ? '探索彩妝品類' : 'EXPLORE OUR CATEGORIES' }}</p>
              <h2>{{ language === 'zh' ? '探索彩妝品類' : 'Discover Our Makeup Categories' }}</h2>
            </div>
            <div class="makeup-category-grid">
              <a v-for="category in makeupCategories" :key="category.name" class="makeup-category-card" href="#makeup-solutions">
                <img :src="assetPath(category.image)" :alt="language === 'zh' ? category.zhName : category.name" loading="lazy" />
                <span class="makeup-category-copy"><strong>{{ language === 'zh' ? category.zhName : category.name }}</strong><small>{{ language === 'zh' ? category.zhDetail : category.detail }}</small></span>
                <span class="makeup-category-arrow" aria-hidden="true">＋</span>
              </a>
            </div>
          </section>
        </div>
      </div>

      <section id="makeup-solutions" class="makeup-story-section">
        <div class="makeup-row-heading">
          <div><p class="eyebrow">{{ language === 'zh' ? '量身打造，符合品牌需求' : 'TAILORED FOR YOUR BRAND' }}</p><h2>{{ language === 'zh' ? '符合品牌需求的產品方案' : 'What your brand needs.' }}</h2></div>
          <div class="makeup-row-actions">
            <a class="text-link" href="#contact">{{ language === 'zh' ? '瀏覽所有方案' : 'VIEW ALL SOLUTIONS' }} <span aria-hidden="true">↗</span></a>
            <div class="makeup-coverflow-controls">
              <button type="button" :aria-label="language === 'zh' ? '上一個方案' : 'Previous solution'" @click="moveMakeupSolutionPage(-1)">←</button>
              <button type="button" :aria-label="language === 'zh' ? '下一個方案' : 'Next solution'" @click="moveMakeupSolutionPage(1)">→</button>
            </div>
          </div>
        </div>
        <div class="makeup-coverflow" aria-live="polite">
          <img class="makeup-coverflow-bg" :src="assetPath(makeupTextureImages[makeupSolutionPage % makeupTextureImages.length])" alt="" aria-hidden="true" />
          <div class="makeup-coverflow-shade"></div>
          <button
            v-for="(item, index) in solutions"
            :key="item.name"
            class="makeup-coverflow-card"
            :class="{ active: index === makeupSolutionPage }"
            :style="makeupSolutionCardStyle(index)"
            type="button"
            :aria-label="language === 'zh' ? item.zhName : item.name"
            :aria-current="index === makeupSolutionPage ? 'true' : undefined"
            @click="makeupSolutionPage = index"
          >
            <img :src="assetPath(makeupTextureImages[index % makeupTextureImages.length])" :alt="language === 'zh' ? `${item.zhName}彩妝質地` : `${item.name} cosmetic texture`" />
            <span class="makeup-coverflow-card-copy">
              <small>{{ language === 'zh' ? item.zhCategory : item.category }}</small>
              <strong>{{ language === 'zh' ? item.zhName : item.name }}</strong>
              <i aria-hidden="true">↗</i>
            </span>
          </button>
        </div>
        <div class="makeup-coverflow-status"><span>{{ String(makeupSolutionPage + 1).padStart(2, '0') }}</span><i></i><span>{{ String(solutions.length).padStart(2, '0') }}</span></div>
      </section>

      <section class="makeup-story-section makeup-inspiration">
        <div class="makeup-row-heading">
          <div><p class="eyebrow">{{ language === 'zh' ? '美妝靈感與趨勢' : 'BEAUTY INSPIRATION' }}</p><h2>{{ language === 'zh' ? '一起創造美妝新可能' : "Creating What's Next." }}</h2></div>
          <div class="makeup-row-actions">
            <a class="text-link" href="/video">{{ language === 'zh' ? '瀏覽所有靈感' : 'VIEW ALL INSPIRATION' }} <span aria-hidden="true">↗</span></a>
            <div class="makeup-feature-controls">
              <button type="button" :aria-label="language === 'zh' ? '上一個美妝靈感' : 'Previous inspiration'" @click="moveMakeupFeature('inspiration', -1)">←</button>
              <button type="button" :aria-label="language === 'zh' ? '下一個美妝靈感' : 'Next inspiration'" @click="moveMakeupFeature('inspiration', 1)">→</button>
            </div>
          </div>
        </div>
        <div class="makeup-feature-slider">
          <a v-for="(item, index) in makeupInspirationItems" :key="item.name" class="makeup-feature-card" :class="{ active: index === makeupInspirationFocus }" href="/video" @mouseenter="makeupInspirationFocus = index" @focus="makeupInspirationFocus = index">
            <img :src="assetPath(makeupEditorialImages[(index + 1) % makeupEditorialImages.length])" :alt="language === 'zh' ? item.zhName : item.name" loading="lazy" />
            <span class="makeup-feature-shade"></span>
            <span class="makeup-feature-copy"><small>{{ language === 'zh' ? item.zhCategory : item.category }}</small><strong>{{ language === 'zh' ? item.zhName : item.name }}</strong><i aria-hidden="true">↗</i></span>
          </a>
        </div>
      </section>

      <section class="makeup-story-section makeup-insights">
        <div class="makeup-row-heading">
          <div><p class="eyebrow">BEAUTY INSIGHTS</p><h2>{{ language === 'zh' ? '美妝趨勢洞察' : 'Ideas Into Insights.' }}</h2></div>
          <div class="makeup-row-actions">
            <a class="text-link" href="/video">{{ language === 'zh' ? '瀏覽所有洞察' : 'VIEW ALL INSIGHTS' }} <span aria-hidden="true">↗</span></a>
            <div class="makeup-feature-controls">
              <button type="button" :aria-label="language === 'zh' ? '上一個美妝洞察' : 'Previous insight'" @click="moveMakeupFeature('insight', -1)">←</button>
              <button type="button" :aria-label="language === 'zh' ? '下一個美妝洞察' : 'Next insight'" @click="moveMakeupFeature('insight', 1)">→</button>
            </div>
          </div>
        </div>
        <div class="makeup-feature-slider makeup-feature-slider--light">
          <a v-for="(item, index) in makeupInsights" :key="item.name" class="makeup-feature-card" :class="{ active: index === makeupInsightFocus }" href="/video" @mouseenter="makeupInsightFocus = index" @focus="makeupInsightFocus = index">
            <img :src="assetPath(makeupTextureImages[(index + 2) % makeupTextureImages.length])" :alt="language === 'zh' ? item.zhName : item.name" loading="lazy" />
            <span class="makeup-feature-shade"></span>
            <span class="makeup-feature-copy"><small>{{ language === 'zh' ? item.zhCategory : item.category }}</small><strong>{{ language === 'zh' ? item.zhName : item.name }}</strong><i aria-hidden="true">↗</i></span>
          </a>
        </div>
      </section>

      <section class="makeup-process">
        <div class="makeup-section-heading"><p class="eyebrow">{{ language === 'zh' ? '一站式解決方案' : 'TURNKEY SOLUTION' }}</p><h2>{{ language === 'zh' ? '從構想到交付，陪你完成每一步' : 'From idea to delivery.' }}</h2></div>
        <div class="makeup-process-grid">
          <article v-for="step in makeupProcess" :key="step.number" class="makeup-process-step">
            <span class="makeup-process-number">{{ step.number }}</span>
            <span class="makeup-process-icon" aria-hidden="true">
              <svg v-if="step.number === '01'" viewBox="0 0 48 48"><rect x="12" y="9" width="24" height="32" rx="3"/><path d="M19 9V6h10v3M18 19h12M18 26h8M18 33h6"/></svg>
              <svg v-else-if="step.number === '02'" viewBox="0 0 48 48"><path d="M19 6h10M21 6v11L12 34a5 5 0 0 0 4.4 7h15.2a5 5 0 0 0 4.4-7l-9-17V6M16 31h16"/><path d="M21 35h.1M27 35h.1"/></svg>
              <svg v-else-if="step.number === '03'" viewBox="0 0 48 48"><circle cx="24" cy="24" r="17"/><path d="m16 24 5 5 11-12"/></svg>
              <svg v-else-if="step.number === '04'" viewBox="0 0 48 48"><path d="M12 6h18l6 6v30H12zM30 6v7h6M18 20h12M18 34h12"/><path d="M26.5 25.5c-1-1.5-6-1.5-6 1 0 3 6 1 6 4 0 2.5-5 2.5-6 1M23.5 23v11"/></svg>
              <svg v-else-if="step.number === '05'" viewBox="0 0 48 48"><path d="m8 15 16-8 16 8-16 8zM8 15v19l16 8 16-8V15M24 23v19"/><path d="m31 10-16 8"/></svg>
              <svg v-else-if="step.number === '06'" viewBox="0 0 48 48"><path d="M6 41V20l11 6V16l11 6V10h8v31zM36 18h6v23H6"/><path d="M13 33h4M23 33h4M33 33h4"/></svg>
              <svg v-else-if="step.number === '07'" viewBox="0 0 48 48"><path d="M5 12h25v23H5zM30 21h7l6 7v7H30z"/><circle cx="14" cy="37" r="4"/><circle cx="36" cy="37" r="4"/><path d="M18 37h14"/></svg>
              <svg v-else viewBox="0 0 48 48"><circle cx="24" cy="20" r="6"/><path d="M11 23v-3a13 13 0 0 1 26 0v3M11 22h4v10h-4a3 3 0 0 1-3-3v-4a3 3 0 0 1 3-3ZM37 22h-4v10h4a3 3 0 0 0 3-3v-4a3 3 0 0 0-3-3ZM37 32c0 5-4 6-8 6M15 42c2-5 5-8 9-8"/></svg>
            </span>
            <h3>{{ language === 'zh' ? step.zhName : step.name }}</h3>
          </article>
        </div>
      </section>

      <section class="faq-section section-pad makeup-home-faq">
        <div class="faq-heading"><p class="eyebrow">{{ copy.faqEyebrow }}</p><h2>{{ copy.faqTitle }}</h2><p>{{ copy.faqSubtitle }}</p></div>
        <div class="faq-list">
          <details v-for="(item, index) in questions" :key="item.question" :open="index === 0">
            <summary><span>{{ language === 'zh' ? item.zhQuestion : item.question }}</span><span class="faq-plus" aria-hidden="true"></span></summary>
            <p>{{ language === 'zh' ? item.zhAnswer : item.answer }}</p>
          </details>
        </div>
      </section>
    </main>

    <main v-else-if="currentMakeupCategory" key="makeup-category" class="makeup-category-page">
      <div class="makeup-category-layout" :class="{ 'is-product-detail': currentCatalogItem }">
        <aside v-if="!currentCatalogItem" class="makeup-side-nav makeup-category-side" :aria-label="language === 'zh' ? '彩妝品類導覽' : 'Makeup category navigation'">
          <a class="makeup-side-title" href="/makeup">{{ language === 'zh' ? '彩妝' : 'Makeup' }}</a>
          <div v-for="category in makeupCategories" :key="category.name" class="makeup-side-group" :class="{ 'is-expanded': expandedMakeupCategory === category.name, 'is-current': currentMakeupCategory.slug === category.slug }">
            <div class="makeup-side-row">
              <a class="makeup-side-category-link" :href="`/makeup/${category.slug}`" :aria-current="currentMakeupCategory.slug === category.slug && !currentMakeupProductSlug ? 'page' : undefined">{{ language === 'zh' ? category.zhName : category.name }}</a>
              <button class="makeup-side-toggle" type="button" :aria-expanded="expandedMakeupCategory === category.name" :aria-controls="`category-side-${category.slug}`" @click="toggleMakeupCategory(category.name)">
                <span class="makeup-side-more">{{ expandedMakeupCategory === category.name ? 'CLOSE' : 'MORE' }}</span>
              </button>
            </div>
            <div v-show="expandedMakeupCategory === category.name" :id="`category-side-${category.slug}`" class="makeup-side-submenu">
              <a v-for="(item, index) in category.items" :key="item" :class="{ active: currentMakeupProductSlug === category.itemSlugs[index] }" :href="`/makeup/${category.slug}/${category.itemSlugs[index]}`" :aria-current="currentMakeupProductSlug === category.itemSlugs[index] ? 'page' : undefined">
                <span>{{ language === 'zh' ? category.zhItems[index] : item }}</span><span aria-hidden="true">→</span>
              </a>
            </div>
          </div>
        </aside>

        <div class="makeup-category-content">
          <section v-if="!currentCatalogItem" class="makeup-category-hero">
            <img :src="assetPath(currentMakeupCategory.image)" :alt="language === 'zh' ? currentMakeupCategory.zhName : currentMakeupCategory.name" />
            <span class="makeup-category-hero-shade"></span>
            <div class="makeup-category-hero-copy">
              <nav class="makeup-breadcrumb" aria-label="Breadcrumb"><a href="/">{{ language === 'zh' ? '首頁' : 'Home' }}</a><span>›</span><a href="/makeup">{{ language === 'zh' ? '彩妝' : 'Makeup' }}</a><span>›</span><span>{{ language === 'zh' ? currentMakeupCategory.zhName : currentMakeupCategory.name }}</span></nav>
              <p class="eyebrow">{{ language === 'zh' ? '客製彩妝產品' : 'CUSTOM MAKEUP PRODUCTS' }}</p>
              <h1>{{ currentCatalogItem ? (language === 'zh' ? currentCatalogItem.zhName : currentCatalogItem.name) : (language === 'zh' ? currentMakeupCategory.zhName : currentMakeupCategory.name) }}</h1>
              <p>{{ language === 'zh' ? currentMakeupCategory.zhDetail : currentMakeupCategory.detail }}</p>
            </div>
          </section>

          <section v-if="!currentCatalogItem" class="makeup-product-listing makeup-shop-listing">
            <div class="makeup-product-listing-heading">
              <div><p class="eyebrow">{{ language === 'zh' ? '商品導覽' : 'PRODUCT GUIDE' }}</p><h2>{{ language === 'zh' ? `所有${currentMakeupCategory.zhName}產品` : `All ${currentMakeupCategory.name} Products` }}</h2></div>
              <p>{{ language === 'zh' ? '從配方、色彩、質地到包裝，依照品牌需求提供完整客製開發。' : 'Customize formula, color, texture and packaging around your brand needs.' }}</p>
            </div>
            <div class="makeup-product-list makeup-shop-grid">
              <article v-for="product in paginatedMakeupProducts" :key="product.slug" class="makeup-shop-card">
                <a class="makeup-shop-image" :href="`/makeup/${currentMakeupCategory.slug}/${product.slug}`"><img :src="assetPath(product.image)" :alt="language === 'zh' ? product.zhName : product.name" /></a>
                <div class="makeup-shop-footer">
                  <a :href="`/makeup/${currentMakeupCategory.slug}/${product.slug}`">
                    <strong>{{ language === 'zh' ? product.zhName : product.name }}</strong>
                    <p>{{ language === 'zh' ? product.zhDescription : product.description }}</p>
                    <span>{{ language === 'zh' ? '了解更多' : 'READ MORE' }} <i aria-hidden="true">→</i></span>
                  </a>
                </div>
              </article>
            </div>
            <div v-if="hasMoreCatalogProducts" ref="catalogLoadTrigger" class="makeup-infinite-loader" role="status" aria-live="polite">
              <span aria-hidden="true"></span>
              <small>{{ language === 'zh' ? '繼續向下滑動，自動載入更多商品' : 'Keep scrolling to load more products' }}</small>
            </div>
            <p v-else class="makeup-catalog-end">{{ language === 'zh' ? `已顯示全部 ${visibleMakeupProducts.length} 件商品` : `All ${visibleMakeupProducts.length} products displayed` }}</p>
          </section>

          <section v-else class="makeup-product-detail" :class="{ 'is-foundation': currentCatalogItem.slug === 'foundation' }">
            <div class="makeup-product-gallery">
              <div class="makeup-product-thumbnails" role="group" :aria-label="language === 'zh' ? '商品圖片' : 'Product images'">
                <button v-for="(image, index) in currentCatalogItem.gallery" :key="image" type="button" :class="{ active: currentCatalogImage === image }" :aria-label="language === 'zh' ? `查看商品圖片 ${index + 1}` : `View product image ${index + 1}`" :aria-pressed="currentCatalogImage === image" @click="selectedCatalogImage = image">
                  <img :src="assetPath(image)" :alt="language === 'zh' ? `${currentCatalogItem.zhName}商品圖片 ${index + 1}` : `${currentCatalogItem.name} product image ${index + 1}`" />
                </button>
              </div>
              <div class="makeup-product-detail-image"><img :src="assetPath(currentCatalogImage)" :alt="language === 'zh' ? currentCatalogItem.zhName : currentCatalogItem.name" /></div>
            </div>
            <div class="makeup-product-detail-copy">
              <p class="makeup-detail-category">{{ language === 'zh' ? `${currentMakeupCategory.zhName}・${currentMakeupCategory.slug === 'eyebrow' && currentCatalogItem.slug === 'brow-pencil' ? '鉛筆' : currentMakeupCategory.zhName}` : `${currentMakeupCategory.name} · ${currentCatalogItem.name}` }}</p>
              <h1 class="makeup-detail-product-name">{{ language === 'zh' ? currentCatalogItem.zhName : currentCatalogItem.name }}</h1>
              <p class="makeup-detail-sku">SKU: {{ currentCatalogItem.sku }}</p>
              <div class="makeup-detail-rule"></div>
              <h2>{{ language === 'zh' ? 'DETAILS' : 'DETAILS' }}</h2>
              <strong class="makeup-detail-heading">{{ language === 'zh' ? currentCatalogItem.zhDetailHeading : 'PRECISION · LONG-WEAR · MADE FOR YOUR BRAND' }}</strong>
              <p class="makeup-detail-description">{{ language === 'zh' ? currentCatalogItem.zhDescription : currentCatalogItem.description }}</p>
              <p v-for="detail in currentCatalogItem.zhDetails" :key="detail" class="makeup-detail-paragraph">{{ language === 'zh' ? detail : 'Developed for reliable performance, a comfortable feel, and effortless application. Formula, shade, and packaging can be tailored to your brand.' }}</p>
              <div class="makeup-detail-bottom-rule"></div>
              <button class="makeup-inquiry-button" type="button" @click="addToCart(currentCatalogItem)">{{ language === 'zh' ? '加入詢價清單' : 'ADD INQUIRY' }}</button>
            </div>
          </section>

          <aside v-if="currentCatalogItem" class="makeup-recommendation-drawer" :class="{ 'is-open': recommendationsOpen }">
            <button class="makeup-recommendation-toggle" type="button" :aria-expanded="recommendationsOpen" :aria-label="language === 'zh' ? `${recommendationsOpen ? '收合' : '展開'}推薦產品` : `${recommendationsOpen ? 'Collapse' : 'Expand'} recommended products`" @click="recommendationsOpen = !recommendationsOpen">
              <span>{{ language === 'zh' ? '推薦產品' : 'RECOMMENDED' }}</span>
            </button>
            <div class="makeup-recommendation-drawer-head" :inert="!recommendationsOpen" :aria-hidden="!recommendationsOpen"><p class="eyebrow">YOU MAY ALSO LIKE</p><h2>{{ language === 'zh' ? '推薦產品' : 'Recommended Products' }}</h2><button type="button" :aria-label="language === 'zh' ? '關閉推薦產品' : 'Close recommendations'" @click="recommendationsOpen = false">×</button></div>
            <div class="makeup-recommendation-drawer-list" :inert="!recommendationsOpen" :aria-hidden="!recommendationsOpen">
              <a v-for="product in recommendedMakeupProducts" :key="product.slug" :href="`/makeup/${currentMakeupCategory.slug}/${product.slug}`">
                <img :src="assetPath(product.image)" :alt="language === 'zh' ? product.zhName : product.name" />
                <span><small>{{ language === 'zh' ? `${currentMakeupCategory.zhName}彩妝` : `${currentMakeupCategory.name.toUpperCase()} MAKEUP` }}</small><strong>{{ language === 'zh' ? product.zhName : product.name }}</strong></span><i aria-hidden="true">→</i>
              </a>
            </div>
          </aside>
        </div>
      </div>
    </main>

    <main v-else-if="currentPageKey === 'contact'" key="contact" class="contact-page">
      <section class="contact-hero">
        <img src="/banner2.png" :alt="language === 'zh' ? 'Style Beauty Group 彩妝與保養產品' : 'Style Beauty Group makeup and skincare products'" />
        <div class="contact-hero-shade"></div>
        <div class="contact-hero-copy">
          <p class="eyebrow">CONTACT US</p>
          <h1>{{ language === 'zh' ? '一起開發你的美妝產品' : "Let's Develop Your Beauty Products" }}</h1>
          <p>{{ language === 'zh' ? '無論你已有完整的產品構想，或仍在探索可能性，我們的團隊都會陪你找到合適的開發方向。' : "Whether you have a clear brief or are still exploring possibilities, we're here to help." }}</p>
          <strong>Style Beauty Group</strong>
          <span>{{ language === 'zh' ? '彩妝、保養品 OEM／ODM 與自有品牌製造商' : 'OEM, ODM and Private Label makeup & skincare manufacturer' }}</span>
        </div>
      </section>

      <section class="contact-facts" :aria-label="language === 'zh' ? '聯絡資訊' : 'Contact details'">
        <article><i aria-hidden="true">⌖</i><div><strong>{{ language === 'zh' ? '地點' : 'LOCATION' }}</strong><span>{{ language === 'zh' ? '台灣台中市' : 'Taichung City, Taiwan' }}</span><small>{{ language === 'zh' ? '詳細地址請來信洽詢' : 'Exact address available upon inquiry' }}</small></div></article>
        <article><i aria-hidden="true">☎</i><div><strong>{{ language === 'zh' ? '電話' : 'PHONE' }}</strong><a href="tel:+886423370043">+886-4-23370043</a><small>{{ language === 'zh' ? '歡迎來電洽詢' : 'Contact us for details' }}</small></div></article>
        <article><i aria-hidden="true">✉</i><div><strong>EMAIL</strong><a href="mailto:style-diana@stylebeautygroup.com">style-diana@stylebeautygroup.com</a><small>{{ language === 'zh' ? '歡迎來信洽詢' : 'Contact us for details' }}</small></div></article>
        <article><i aria-hidden="true">◷</i><div><strong>{{ language === 'zh' ? '服務時間' : 'WORKING HOURS' }}</strong><span>{{ language === 'zh' ? '週一至週五 8:30–17:30' : 'Monday–Friday, 8:30 AM–5:30 PM' }}</span><small>{{ language === 'zh' ? '國定假日除外' : 'Excluding weekends and national holidays' }}</small></div></article>
      </section>

      <section class="contact-workspace">
        <div class="contact-mode-intro">
          <p class="eyebrow">LET'S WORK TOGETHER</p>
          <h2>{{ language === 'zh' ? '選擇最適合你的聯絡方式' : 'Choose how you would like to begin' }}</h2>
          <p>{{ language === 'zh' ? '直接聯絡團隊，或透過簡短的引導表單整理你的產品需求。' : 'Contact our team directly or use our guided form to shape your product inquiry.' }}</p>
        </div>

        <div class="contact-mode-switch" :class="{ 'is-inquiry': contactMode === 'inquiry' }" role="tablist" :aria-label="language === 'zh' ? '聯絡方式' : 'Contact method'">
          <span class="contact-mode-indicator" aria-hidden="true"></span>
          <button type="button" role="tab" :aria-selected="contactMode === 'email'" :tabindex="contactMode === 'email' ? 0 : -1" @click="contactMode = 'email'">
            <i aria-hidden="true">✉</i><span><small>EMAIL OUR TEAM</small><strong>{{ language === 'zh' ? '直接聯絡團隊' : 'I Have a Project in Mind' }}</strong></span>
          </button>
          <button type="button" role="tab" :aria-selected="contactMode === 'inquiry'" :tabindex="contactMode === 'inquiry' ? 0 : -1" @click="contactMode = 'inquiry'">
            <i aria-hidden="true">◫</i><span><small>START AN INQUIRY</small><strong>{{ language === 'zh' ? '開始產品詢問' : 'I Need Help Getting Started' }}</strong></span>
          </button>
        </div>

        <Transition name="contact-slide" mode="out-in">
          <section v-if="contactMode === 'email'" key="email" class="contact-email-panel contact-email-form-panel" role="tabpanel">
            <div class="contact-email-copy">
              <p class="eyebrow">EMAIL OUR TEAM</p>
              <h3>{{ language === 'zh' ? '直接告訴我們你的想法' : 'Tell us about your idea' }}</h3>
              <p>{{ language === 'zh' ? '填寫基本聯絡資訊與想詢問的內容，我們的團隊會盡快與你聯繫。' : 'Leave your contact details and message. Our team will get back to you shortly.' }}</p>
              <div class="contact-email-note"><i aria-hidden="true">✉</i><span><small>EMAIL</small><a href="mailto:style-diana@stylebeautygroup.com">style-diana@stylebeautygroup.com</a></span></div>
            </div>
            <form class="contact-quick-form" @submit.prevent="sendDirectEmail">
              <div class="contact-quick-grid">
                <label><span>{{ language === 'zh' ? '姓名 *' : 'Name *' }}</span><input v-model.trim="directForm.name" type="text" autocomplete="name" required :placeholder="language === 'zh' ? '請輸入姓名' : 'Enter your name'" /></label>
                <label><span>Email *</span><input v-model.trim="directForm.email" type="email" autocomplete="email" required :placeholder="language === 'zh' ? '請輸入電子信箱' : 'Enter your email'" /></label>
                <label><span>{{ language === 'zh' ? '公司名稱' : 'Company' }}</span><input v-model.trim="directForm.company" type="text" autocomplete="organization" :placeholder="language === 'zh' ? '請輸入公司或品牌名稱' : 'Enter company or brand name'" /></label>
                <label><span>{{ language === 'zh' ? '國家' : 'Country' }}</span><input v-model.trim="directForm.country" type="text" autocomplete="country-name" :placeholder="language === 'zh' ? '請輸入國家' : 'Enter your country'" /></label>
                <label class="contact-quick-wide"><span>WhatsApp</span><input v-model.trim="directForm.whatsapp" type="tel" autocomplete="tel" :placeholder="language === 'zh' ? '國碼與電話號碼' : 'Country code and phone number'" /></label>
                <label class="contact-quick-wide"><span>{{ language === 'zh' ? '訊息 *' : 'Message *' }}</span><textarea v-model.trim="directForm.message" rows="5" required :placeholder="language === 'zh' ? '請輸入想詢問的內容' : 'Tell us how we can help'" /></label>
                <label class="contact-quick-wide contact-captcha-field"><span>{{ language === 'zh' ? '防機器人驗證 *' : 'Captcha *' }}</span><span class="contact-captcha-row"><strong :aria-label="language === 'zh' ? `驗證碼 ${directCaptcha}` : `Captcha code ${directCaptcha}`">{{ directCaptcha }}</strong><input v-model.trim="directForm.captcha" type="text" inputmode="numeric" required :placeholder="language === 'zh' ? '請輸入左側號碼' : 'Enter the code'" @input="directCaptchaError = ''" /></span><small v-if="directCaptchaError" role="alert">{{ directCaptchaError }}</small></label>
              </div>
              <button class="button button-primary contact-quick-submit" type="submit">{{ language === 'zh' ? '送出' : 'SEND' }} <span aria-hidden="true">→</span></button>
            </form>
          </section>

          <section v-else key="inquiry" class="contact-inquiry-embed" role="tabpanel" :aria-label="language === 'zh' ? '產品詢問引導表單' : 'Guided product inquiry form'">
            <iframe ref="inquiryFrame" class="contact-inquiry-frame" title="OEM / ODM Product Inquiry" :srcdoc="inquiryWizardHtml" :style="{ height: `${inquiryFrameHeight}px` }"></iframe>
          </section>
        </Transition>
      </section>
    </main>

    <main v-else key="interior" class="interior-page">
      <section class="interior-hero">
        <img :src="`https://images.unsplash.com/${displayPage.image}?auto=format&fit=crop&w=2000&q=85`" :alt="displayPage.title" />
        <div class="interior-hero-shade"></div>
        <div class="interior-hero-copy">
          <p class="eyebrow">{{ displayPage.eyebrow }}</p>
          <h1>{{ displayPage.title }}</h1>
          <p>{{ displayPage.description }}</p>
        </div>
      </section>
      <section class="interior-content">
        <div class="interior-copy">
          <p class="eyebrow">{{ language === 'zh' ? 'STYLE BEAUTY GROUP · 美妝 OEM / ODM' : 'STYLE BEAUTY GROUP · OEM / ODM' }}</p>
          <h2>{{ displayPage.heading }}</h2>
          <p>{{ displayPage.body }}</p>
        </div>
        <ul class="interior-features">
          <li v-for="feature in displayPage.features" :key="feature">{{ feature }}</li>
        </ul>
        <a class="button button-primary" :href="currentPageKey === 'contact' ? 'mailto:style-diana@stylebeautygroup.com' : '/contact'">{{ copy.discuss }} <span aria-hidden="true">↗</span></a>
      </section>
      <nav class="interior-related" :aria-label="copy.related">
        <a href="/makeup">{{ copy.nav[2] }} <span aria-hidden="true">↗</span></a>
        <a href="/sun-care">{{ copy.nav[3] }} <span aria-hidden="true">↗</span></a>
        <a href="/skincare">{{ copy.nav[4] }} <span aria-hidden="true">↗</span></a>
        <a href="/mens-care">{{ copy.nav[5] }} <span aria-hidden="true">↗</span></a>
      </nav>
    </main>
    </Transition>

    <a
      v-if="currentPageKey !== 'contact'"
      class="ai-service-link"
      href="/contact"
      :aria-label="language === 'zh' ? 'AI 智能客服，前往聯絡我們' : 'AI customer service, contact us'"
    >
      <svg viewBox="0 0 64 64" aria-hidden="true">
        <circle cx="32" cy="25" r="8" />
        <path d="M17 28v-3a15 15 0 0 1 30 0v3" />
        <path d="M17 27h4v11h-4a3 3 0 0 1-3-3v-5a3 3 0 0 1 3-3ZM47 27h-4v11h4a3 3 0 0 0 3-3v-5a3 3 0 0 0-3-3Z" />
        <path d="M47 38c0 6-4 8-9 8M38 46h-4" />
        <path d="M18 53c2.5-8 8-12 14-12s11.5 4 14 12" />
      </svg>
      <span class="ai-service-tooltip">{{ language === 'zh' ? 'AI 智能客服' : 'AI Customer Service' }}</span>
    </a>

    <footer id="contact" class="site-footer">
      <div class="footer-main">
        <div class="footer-copy"><p class="eyebrow">{{ copy.footerEyebrow }}</p><h2>{{ copy.footerTitle }}</h2><p>{{ copy.footerBody }}</p></div>
        <div class="footer-actions">
          <a class="button button-primary" href="mailto:style-diana@stylebeautygroup.com">{{ copy.contactUs }} <span aria-hidden="true">↗</span></a>
          <a class="footer-back-top" href="#top" :aria-label="copy.backTop">↑</a>
        </div>
      </div>
      <div class="footer-bottom"><span>© 2026 STYLE BEAUTY GROUP. ALL RIGHTS RESERVED.</span></div>
    </footer>
  </div>
</template>
