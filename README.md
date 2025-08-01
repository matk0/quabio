# MITO - Slovenský Zdravotný Asistent 🧬

MITO je RAG (Retrieval-Augmented Generation) chatbot špecializovaný na zdravie, epigenetiku a kvantovú biológiu. Aplikácia poskytuje odpovede v slovenčine na základe databázy 179 odborných článkov.

## Funkcie

- 🇸🇰 **Plná podpora slovenčiny** s diakritickými znamienkami
- 🧬 **Špecializácia** na zdravie, epigenetiku, mitochondrie a kvantovú biológiu
- 📚 **Citovanie zdrojov** pre každú odpoveď
- 💻 **Moderné React rozhranie** s TypeScript
- ⚡ **FastAPI backend** s async podporou
- 🔍 **Pokročilé vyhľadávanie** cez ChromaDB vector database
- 📱 **Responzívny dizajn** pre mobily a tablety

## Technológie

### Backend
- **FastAPI** - moderne Python web framework
- **LangChain** - RAG implementation
- **ChromaDB** - vector database
- **OpenAI GPT-4-turbo** - slovenčina optimalizované odpovede
- **OpenAI text-embedding-3-large** - multilingual embeddings

### Frontend
- **React 18** s TypeScript
- **Tailwind CSS** - styling
- **Framer Motion** - animácie
- **React Query** - state management
- **Axios** - API komunikácia

## Inštalácia a Spustenie

### Predpoklady
- Python 3.11+
- Node.js 18+
- OpenAI API kľúč
- Conda (doporučené)

### Lokálne spustenie

1. **Klonujte repository**
   ```bash
   git clone <repository-url>
   cd mito
   ```

2. **Nastavte environment variables**
   ```bash
   cp .env.example .env
   # Upravte .env súbor s vašim OpenAI API kľúčom
   ```

3. **Backend setup**
   ```bash
   cd backend
   conda create -n mito-backend python=3.11
   conda activate mito-backend
   pip install -r requirements.txt
   ```

4. **Inicializácia RAG systému**
   ```bash
   python setup_rag.py
   ```

5. **Spustenie backend servera**
   ```bash
   uvicorn app.main:app --reload
   ```

6. **Frontend setup** (nový terminál)
   ```bash
   cd frontend
   npm install
   npm start
   ```

Aplikácia bude dostupná na `http://localhost:3000`

### Docker spustenie

1. **Nastavte environment variables**
   ```bash
   cp .env.example .env
   # Upravte .env súbor
   ```

2. **Build a spustenie**
   ```bash
   docker-compose up --build
   ```

## API Dokumentácia

Backend poskytuje REST API s nasledujúcimi endpoints:

- `POST /api/chat` - Pošle správu chatbotu
- `GET /api/health` - Health check
- `GET /api/stats` - Štatistiky o RAG système
- `GET /docs` - Swagger dokumentácia

### Príklad API volania

```bash
curl -X POST "http://localhost:8000/api/chat" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Čo je epigenetika?",
    "session_id": "optional-session-id"
  }'
```

## Deployment na Digital Ocean

### App Platform Deployment

1. **Vytvorte nový App v Digital Ocean**
2. **Pripojte váš GitHub repository**
3. **Nastavte environment variables**:
   - `OPENAI_API_KEY`
   - `ENVIRONMENT=production`
4. **Nakonfigurujte build settings**:
   - Backend: `backend/` directory
   - Frontend: `frontend/` directory

### Manuálny deployment

```bash
# Build images
docker build -t mito-backend ./backend
docker build -t mito-frontend ./frontend

# Deploy to registry
docker tag mito-backend registry.digitalocean.com/your-registry/mito-backend
docker push registry.digitalocean.com/your-registry/mito-backend

# Deploy to droplet or Kubernetes
```

## Vývoj

### Backend štruktúra
```
backend/
├── app/
│   ├── api/          # FastAPI routes
│   ├── rag/          # RAG system components
│   └── models/       # Pydantic models
├── data/articles/    # Slovak articles (JSON)
└── setup_rag.py     # RAG initialization
```

### Frontend štruktúra
```
frontend/
├── src/
│   ├── components/   # React components
│   ├── hooks/        # Custom hooks
│   ├── services/     # API services
│   └── types/        # TypeScript types
```

### Pridanie nových článkov

1. Uložte JSON súbory do `backend/data/articles/`
2. Spustite `python setup_rag.py` pre reindexovanie
3. Reštartujte backend server

### Prispôsobenie promptov

Upravte Slovak prompt v `backend/app/rag/chain.py`:

```python
slovak_prompt = ChatPromptTemplate.from_messages([
    ("system", "Váš upravený system prompt..."),
    ("human", "Kontext: {context}\n\nOtázka: {question}")
])
```

## Testovanie

### Backend testy
```bash
cd backend
pytest tests/
```

### Frontend testy
```bash
cd frontend
npm test
```

### End-to-end testy
```bash
# Spustite oba servery
npm run e2e
```

## Prispievanie

1. Fork repository
2. Vytvorte feature branch
3. Commitnite zmeny s jasným popisom
4. Otvorte Pull Request

## Licencia

MIT License - viď [LICENSE](LICENSE) súbor.

## Podpora

Pre technické otázky alebo problémy:
- Otvorte Issue na GitHub
- Kontaktujte tím cez [email]

---

**MITO** - Váš inteligentný sprievodca svetom zdravia a vedy! 🧬✨