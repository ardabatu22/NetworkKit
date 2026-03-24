# NetworkKit Nasıl Çalışır?

## Bu Kütüphane Ne İşe Yarar?

Bir mobil uygulama yaptığında, neredeyse her zaman internetten veri çekmek zorunda kalırsın. Mesela:
- Bir haber uygulamasında haberleri sunucudan çekmek
- Bir e-ticaret uygulamasında ürünleri listelemek
- Kullanıcı girişi yapmak
- Profil fotoğrafı yüklemek

Her seferinde bu işlemleri sıfırdan yazmak yerine, **NetworkKit** sana hazır bir altyapı sunar. Sen sadece "şu adresten şu veriyi çek" dersin, gerisini o halleder.

---

## Gerçek Hayat Benzetmesi

NetworkKit'i bir **kargo şirketi** gibi düşün:

| Kargo Şirketi | NetworkKit |
|----------------|------------|
| Gönderilecek adres | `Endpoint` (API adresi) |
| Kargo formu doldurma | `RequestBuilder` (istek hazırlama) |
| Gönderiden önce etiket yapıştırma | `RequestInterceptor` (token ekleme vs.) |
| Kargo teslim edilemezse tekrar deneme | `RetryPolicy` (otomatik tekrar deneme) |
| Teslim sonrası bildirim | `ResponseInterceptor` (cevabı işleme) |
| Kargo şirketinin kendisi | `URLSessionClient` (asıl işi yapan) |

---

## Temel Yapı Taşları

### 1. Endpoint — "Nereye istek atacağım?"

Bir API'ye istek atmak için şunları bilmen gerekir:
- **Adres** (URL): `https://api.example.com`
- **Yol** (Path): `/users`
- **Yöntem** (Method): Veri mi çekiyorsun (GET)? Veri mi gönderiyorsun (POST)?
- **Başlıklar** (Headers): Kimlik doğrulama bilgisi, içerik tipi vs.
- **Gövde** (Body): Gönderilecek veri (mesela yeni kullanıcı bilgisi)

NetworkKit'te bunları bir `Endpoint` olarak tanımlarsın:

```swift
// "Tüm kullanıcıları getir" endpoint'i
struct GetUsersEndpoint: Endpoint {
    var baseURL: URL { URL(string: "https://api.example.com")! }
    var path: String { "/users" }
    var method: HTTPMethod { .get }
}
```

Bu kadar. Artık bu endpoint'i kullanarak istek atabilirsin.

### 2. HTTPMethod — "Ne tür bir istek?"

HTTP'de 5 temel istek türü vardır:

| Method | Ne Zaman Kullanılır? | Örnek |
|--------|----------------------|-------|
| **GET** | Veri çekmek | Ürün listesini getir |
| **POST** | Yeni veri oluşturmak | Yeni kullanıcı kaydet |
| **PUT** | Mevcut veriyi tamamen güncellemek | Profili güncelle |
| **PATCH** | Mevcut verinin bir kısmını güncellemek | Sadece adı değiştir |
| **DELETE** | Veri silmek | Hesabı sil |

### 3. HTTPHeader — "İsteğe ek bilgi ekle"

Header'lar isteğe eklenen meta bilgilerdir. En yaygın kullanımlar:

```swift
// "Ben JSON gönderiyorum"
.contentType("application/json")

// "JSON formatında cevap istiyorum"
.accept("application/json")

// "Benim kimliğim bu" (giriş yapmış kullanıcı için)
.bearerToken("abc123xyz")
```

### 4. NetworkError — "Bir şeyler ters gitti"

İnternet istekleri her zaman başarılı olmaz. NetworkKit hataları anlamlı kategorilere ayırır:

| Hata | Anlamı |
|------|--------|
| `invalidURL` | URL geçersiz |
| `unauthorized` | Oturum süresi dolmuş veya giriş yapılmamış (401) |
| `requestFailed(statusCode, data)` | Sunucu hata döndü (404, 500 vs.) |
| `decodingFailed` | Gelen veri beklenen formatta değil |
| `timeout` | İstek zaman aşımına uğradı |
| `noConnection` | İnternet bağlantısı yok |
| `noData` | Sunucu boş cevap döndü |

Bu sayede her hataya özel davranış yazabilirsin:

```swift
do {
    let users: [User] = try await client.send(endpoint)
} catch NetworkError.unauthorized {
    // Kullanıcıyı giriş ekranına yönlendir
} catch NetworkError.noConnection {
    // "İnternet bağlantınızı kontrol edin" göster
} catch NetworkError.timeout {
    // "Sunucu yanıt vermiyor, tekrar deneyin" göster
}
```

### 5. RequestBuilder — "Endpoint'i gerçek isteğe çevir"

Sen bir `Endpoint` tanımlarsın, ama işletim sistemi `URLRequest` anlıyor. `RequestBuilder` bu çevirmeyi yapar:

```
Senin yazdığın Endpoint  →  RequestBuilder  →  URLRequest (sistem anlıyor)
```

Arkaplanda şunları yapar:
- URL + path'i birleştirir (`https://api.example.com` + `/users`)
- Query parametrelerini ekler (`?page=1&limit=20`)
- Header'ları yerleştirir
- Body'yi JSON formatına çevirir

### 6. Interceptor — "İsteği yolda yakala ve değiştir"

Interceptor'lar bir **güvenlik kapısı** gibidir. İstek gitmeden önce veya cevap geldikten sonra araya girerler.

**Request Interceptor** — İstek gitmeden önce:
```swift
// Her isteğe otomatik olarak kullanıcı token'ı ekle
struct AuthInterceptor: RequestInterceptor {
    let token: String

    func intercept(_ request: URLRequest) async throws -> URLRequest {
        var request = request
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}
```

Bu sayede her endpoint'e tek tek token eklemek zorunda kalmazsın. Interceptor otomatik olarak her isteğe ekler.

**Response Interceptor** — Cevap geldikten sonra:
```swift
// Gelen her cevabı logla (debug için)
struct LoggingInterceptor: ResponseInterceptor {
    func intercept(_ response: HTTPURLResponse, data: Data) async throws -> Data {
        print("Status: \(response.statusCode)")
        print("Data: \(String(data: data, encoding: .utf8) ?? "")")
        return data
    }
}
```

### 7. RetryPolicy — "Başarısız olursa tekrar dene"

Bazen sunucu geçici olarak cevap veremez (yoğunluk, bakım vs.). Bu durumda isteği otomatik olarak tekrar denemek mantıklıdır.

```swift
RetryPolicy(
    maxRetryCount: 3,          // En fazla 3 kez dene
    delay: .seconds(1),        // İlk denemeden önce 1 saniye bekle
    backoffMultiplier: 2.0,    // Her denemede bekleme süresini 2x artır
    retryableStatusCodes: [500, 502, 503]  // Sadece bu hatalarda tekrar dene
)
```

**Exponential Backoff** nasıl çalışır:
```
1. deneme başarısız → 1 saniye bekle → tekrar dene
2. deneme başarısız → 2 saniye bekle → tekrar dene
3. deneme başarısız → 4 saniye bekle → tekrar dene
4. hâlâ başarısız   → hata fırlat
```

Bekleme süresinin artmasının sebebi: sunucu zaten yoğunsa, hızlı hızlı istek atmak işleri daha da kötüleştirir.

### 8. URLSessionClient — "Her Şeyi Bir Araya Getiren Motor"

Bu sınıf tüm parçaları birleştirir. İstek gönderme akışı şöyle çalışır:

```
1. Endpoint al
2. RequestBuilder ile URLRequest'e çevir
3. Request Interceptor'lardan geçir (token ekle vs.)
4. URLSession ile isteği gönder
5. Hata varsa ve retry policy uygunsa → tekrar dene
6. Başarılıysa Response Interceptor'lardan geçir
7. JSON'ı decode et ve sonucu döndür
```

```swift
// Client'ı yapılandır
let client = URLSessionClient(
    retryPolicy: RetryPolicy(maxRetryCount: 3, delay: .seconds(1)),
    requestInterceptors: [AuthInterceptor(token: "abc123")]
)

// İstek at — tek satır
let users: [User] = try await client.send(GetUsersEndpoint())
```

### 9. MultipartFormData — "Dosya Yükle"

Fotoğraf veya dosya yüklemek için özel bir format gerekir: `multipart/form-data`. Bu yapı, hem metin hem dosya verisini tek bir istekte gönderebilmeni sağlar.

```swift
var form = MultipartFormData()
form.addField(name: "caption", value: "Profil fotoğrafım")
form.addFile(
    name: "photo",
    data: imageData,
    fileName: "profil.jpg",
    mimeType: "image/jpeg"
)

let body = form.encode() // Gönderilmeye hazır Data
```

---

## Akış Diyagramı

```
┌─────────────────────────────────────────────────────┐
│                    SEN (Geliştirici)                 │
│                                                     │
│   let users: [User] = try await client.send(ep)     │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────┐
│                  RequestBuilder                      │
│         Endpoint → URLRequest dönüşümü              │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────┐
│              Request Interceptors                    │
│        Token ekleme, header değiştirme vs.          │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────┐
│                  URLSession                          │
│            İsteği internete gönder                   │
└─────────────────────┬───────────────────────────────┘
                      │
              ┌───────┴───────┐
              ▼               ▼
         Başarılı          Başarısız
              │               │
              │         Retry Policy
              │          kontrol et
              │               │
              │        ┌──────┴──────┐
              │        ▼             ▼
              │   Tekrar dene    Hata fırlat
              │
              ▼
┌─────────────────────────────────────────────────────┐
│             Response Interceptors                    │
│           Loglama, veri dönüştürme vs.              │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────┐
│                  JSON Decode                         │
│           Data → Swift modeline çevir               │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
                 [User] 🎉
```

---

## Neden Böyle Tasarlandı?

| Tasarım Kararı | Sebebi |
|-----------------|--------|
| **Protocol-based (Endpoint, NetworkClient)** | Test yazarken sahte (mock) implementasyon kullanabilirsin |
| **Interceptor pattern** | Token ekleme gibi ortak işleri tek yerde yönetirsin |
| **Retry policy** | Geçici hatalarda kullanıcı deneyimi bozulmaz |
| **Sendable uyumlu** | Swift'in modern concurrency sistemiyle güvenle çalışır |
| **SPM paketi** | Herhangi bir projeye tek satırla eklenebilir |

---

## Hızlı Başlangıç Özeti

```swift
// 1. Endpoint tanımla
struct GetPosts: Endpoint {
    var baseURL: URL { URL(string: "https://jsonplaceholder.typicode.com")! }
    var path: String { "/posts" }
    var method: HTTPMethod { .get }
}

// 2. Model tanımla
struct Post: Decodable, Sendable {
    let id: Int
    let title: String
    let body: String
}

// 3. Client oluştur ve kullan
let client = URLSessionClient()
let posts: [Post] = try await client.send(GetPosts())
print(posts.first?.title ?? "")
```

Bu kadar. Üç adımda internetten veri çektin.
