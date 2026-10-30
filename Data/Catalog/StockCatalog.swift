import Foundation

/// Fictional reference values for the assessment. These are not verified market quotations.
enum StockCatalog {
    static let stocks: [Stock] = [
        stock("AAPL", "Apple", 18942, "Apple designs personal devices, software and services, including iPhone, Mac and its services ecosystem."),
        stock("MSFT", "Microsoft", 42876, "Microsoft develops productivity software, cloud infrastructure and computing platforms for people and organizations."),
        stock("NVDA", "NVIDIA", 13285, "NVIDIA develops graphics processors and accelerated computing platforms used in AI, visualization and data centers."),
        stock("GOOGL", "Alphabet", 17534, "Alphabet is the parent of Google, with businesses in search, advertising, cloud computing and emerging technologies."),
        stock("AMZN", "Amazon", 18621, "Amazon operates online retail, logistics, digital entertainment and Amazon Web Services cloud infrastructure."),
        stock("META", "Meta Platforms", 51267, "Meta builds social and communication platforms, including Facebook, Instagram and WhatsApp, alongside immersive computing research."),
        stock("TSLA", "Tesla", 24850, "Tesla develops electric vehicles, energy storage systems and solar products with supporting software and charging infrastructure."),
        stock("NFLX", "Netflix", 68540, "Netflix provides streaming entertainment and produces and distributes films, series and other programming."),
        stock("AMD", "Advanced Micro Devices", 15892, "AMD designs processors and graphics technology for personal computers, gaming consoles and data center systems."),
        stock("INTC", "Intel", 2436, "Intel designs and manufactures computing semiconductors and develops platforms for client and data center applications."),
        stock("ORCL", "Oracle", 14218, "Oracle provides enterprise database technology, cloud infrastructure and business applications."),
        stock("CRM", "Salesforce", 26783, "Salesforce provides cloud software for customer relationships, sales, service, marketing and enterprise analytics."),
        stock("ADBE", "Adobe", 52461, "Adobe creates software and cloud services for creative work, digital documents and customer experiences."),
        stock("PYPL", "PayPal", 7245, "PayPal operates digital payments platforms that help consumers and merchants send, receive and manage payments."),
        stock("UBER", "Uber Technologies", 7582, "Uber connects consumers with mobility, delivery and logistics services through its technology platforms."),
        stock("SHOP", "Shopify", 8374, "Shopify provides commerce software and merchant services for businesses selling online and in person."),
        stock("JPM", "JPMorgan Chase", 21358, "JPMorgan Chase provides consumer and commercial banking, investment banking and asset management services."),
        stock("BAC", "Bank of America", 4127, "Bank of America offers banking, lending, investment and wealth management services to individuals and organizations."),
        stock("GS", "Goldman Sachs", 49863, "Goldman Sachs provides investment banking, markets services and asset and wealth management."),
        stock("V", "Visa", 27896, "Visa operates a global payments network connecting consumers, merchants, financial institutions and other partners."),
        stock("MA", "Mastercard", 46725, "Mastercard provides payment network infrastructure and related technology and services for digital commerce."),
        stock("DIS", "The Walt Disney Company", 9678, "Disney creates entertainment across film, television and streaming and operates parks, experiences and consumer products."),
        stock("KO", "Coca-Cola", 6384, "Coca-Cola develops, markets and distributes a portfolio of nonalcoholic beverage brands worldwide."),
        stock("PEP", "PepsiCo", 17236, "PepsiCo develops and distributes beverages and convenient foods through a broad portfolio of consumer brands."),
        stock("WMT", "Walmart", 8247, "Walmart operates retail stores, e-commerce platforms and membership warehouse clubs offering everyday goods.")
    ]

    private static func stock(_ ticker: String, _ company: String, _ cents: Int, _ description: String) -> Stock {
        Stock(id: ticker, company: company, description: description, referencePrice: Price(cents: cents))
    }
}
