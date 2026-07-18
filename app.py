import streamlit as st
from environs import Env
from langchain_core.prompts import ChatPromptTemplate
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_community.vectorstores import FAISS
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_core.output_parsers import StrOutputParser
import time

# Load resources and initialize environment
def load_resources():
    parser = StrOutputParser()
    env = Env()
    env.read_env(".env")

    api_key = env("GEMINI_API_KEY")
    chat = ChatGoogleGenerativeAI(model="gemini-flash-lite-latest", api_key=api_key)
    embeddings = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")

    try:
        vector_store = FAISS.load_local("vectorDB", embeddings, allow_dangerous_deserialization=True)
    except Exception as e:
        st.error(f"Error loading vector store: {e}")
        return None, None

    template = """
    You are 'RAG_ASK', a reliable and trustworthy AI assistant specifically designed 
    to answer questions about IIITDMJ, developed by Om Singhal,
    who is an undergrad at IIITDMJ pursuing BTech in CSE of 2023 batch.
    Your responses must be strictly based on the provided context.

    - Do not provide information beyond the context.
    - If the context does not cover the question, respond with: 
      "I don't have enough information about this. Please visit www.iiitdmj.ac.in for more details."
    - Avoid assumptions, speculations, or hallucinations.

    Ensure clarity, accuracy, and relevance in your responses.

    Context: {context}

    Question: {question}
    """
    prompt = ChatPromptTemplate.from_template(template)
    llm_chain = prompt | chat | parser
    return llm_chain, vector_store

# Function to get assistant response
def get_assistant_response(user_query, vector_store, llm_chain):
    retriever = vector_store.as_retriever(search_kwargs={"k": 3})
    retrieved_docs = retriever.invoke(user_query)
    context = "\n\n".join([doc.page_content for doc in retrieved_docs])
    input_data = {"context": context, "question": user_query}
    assistant_response = llm_chain.invoke(input_data)
    return assistant_response

# Function to display typing animation for assistant response
def display_typing_animation(response_text):
    response_placeholder = st.empty()
    typing_speed = 00.01  # Adjust typing speed as needed
    displayed_text = ""

    for char in response_text:
        displayed_text += char
        response_placeholder.write(displayed_text)
        time.sleep(typing_speed)

    return response_placeholder

# Load resources
llm_chain, vector_store = load_resources()

# Streamlit UI
st.set_page_config(
    page_title="RAG_ASK", 
    layout="centered"
)

# Add the IIITDMJ logo and heading
logo_path = "photo/iiitdmjLOGO.jpeg"  # Replace with the path to your logo file
col1, col2 = st.columns([1, 4])  # Adjust column widths as needed
with col1:
    st.image(logo_path, width=50)  # Adjust width as per your requirement
with col2:
    st.title("RAG_ASK")
    st.caption("Your AI-Powered IIITDMJ Knowledge Companion")

if vector_store is None:
    st.error("Failed to load vector store. Please check your setup.")
else:
    # Initialize session state for chat history
    if "chat_history" not in st.session_state:
        st.session_state["chat_history"] = []

    # Display previous chat history
    for user_message, assistant_message in st.session_state["chat_history"]:
        st.chat_message("user").write(user_message)
        st.chat_message("assistant").write(assistant_message)

    # Input field for user queries
    user_query = st.chat_input("Ask me anything about IIITDMJ!")
    if user_query:
        # Immediately show the user's query in the chat
        st.chat_message("user").write(user_query)

        # Add a placeholder for assistant's response
        assistant_placeholder = st.chat_message("assistant").empty()

        # Get assistant response
        assistant_response = get_assistant_response(user_query, vector_store, llm_chain)

        # Show assistant's response with typing animation
        display_typing_animation(assistant_response)

        # Add the query and response to the chat history
        st.session_state["chat_history"].append((user_query, assistant_response))
