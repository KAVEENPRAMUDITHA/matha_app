# Location: server/chatbot_service.py
from flask import Flask, request, jsonify
from flask_cors import CORS
import os, base64
from dotenv import load_dotenv

from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_huggingface import HuggingFaceEmbeddings 
from langchain_community.document_loaders import PyPDFLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.vectorstores import FAISS
from langchain_core.messages import HumanMessage, SystemMessage

load_dotenv()
app = Flask(__name__)
CORS(app)

DB_FAISS_PATH = 'vectorstore/db_faiss'
vectorstore = None

def initialize_knowledge_base():
    """Initializes and caches the FAISS vector database from maternal care PDFs."""
    global vectorstore
    embeddings = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")

    # 1. Load from cache if already exists
    if os.path.exists(DB_FAISS_PATH):
        try:
            vectorstore = FAISS.load_local(DB_FAISS_PATH, embeddings, allow_dangerous_deserialization=True)
            return
        except Exception as e:
            print(f"Cache load error: {e}. Rebuilding...")

    # 2. Extract and chunk PDF documents
    pdf_paths = ["data/Maternal & Newborn Strat Plan .pdf", "data/maternal_care_healthcare_workers.pdf"] 
    all_docs = []
    for path in pdf_paths:
        if os.path.exists(path):
            all_docs.extend(PyPDFLoader(path).load())

    if all_docs:
        splits = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=100).split_documents(all_docs)
        vectorstore = FAISS.from_documents(documents=splits, embedding=embeddings)
        vectorstore.save_local(DB_FAISS_PATH)

initialize_knowledge_base()

@app.route('/chat', methods=['POST'])
def chat():
    data = request.json
    user_question = data.get('question', '')
    image_base64 = data.get('image', None)

    llm = ChatGoogleGenerativeAI(model="gemini-flash-latest", temperature=0.3)
    
    system_instruction = (
        "You are an AI Maternal and Infant Healthcare Assistant in Sri Lanka. "
        "If the user asks in Sinhala, respond strictly in natural Sinhala. "
        "Provide evidence-based guidance but include a disclaimer that this is not medical advice. "
        "Strictly answer questions related to maternal, pregnancy, and infant health."
    )

    # Retrieve context from FAISS
    context_text = ""
    if vectorstore:
        relevant_docs = vectorstore.as_retriever().invoke(user_question)
        context_text = "\n\n".join([d.page_content for d in relevant_docs])

    # Construct prompt with multimodal image support
    messages = [SystemMessage(content=system_instruction)]
    prompt_content = f"Context: {context_text}\n\nQuestion: {user_question}"
    
    if image_base64:
        messages.append(HumanMessage(content=[
            {"type": "text", "text": prompt_content},
            {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{image_base64}"}}
        ]))
    else:
        messages.append(HumanMessage(content=prompt_content))

    try:
        response = llm.invoke(messages)
        return jsonify({"answer": response.content})
    except Exception as e:
        return jsonify({"answer": "Error generating response", "error": str(e)}), 500
