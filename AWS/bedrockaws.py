
import imp
import json,os,sys,boto3
from langchain_community.embeddings import BedrockEmbeddings
from langchain_community.llms.bedrock import Bedrock
import streamlit as st

# Data ingestion

import numpy as np
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.document_loaders import PyPDFDirectoryLoader

# Vector Embedding and vector store
from langchain_community.vectorstores import FAISS

# LLM Models
from langchain.prompts import PromptTemplate
from langchain.chains import RetrievalQA

# Bedrock clients
bedrock=boto3.client(service_name="bedrock-runtime",region_name="us-east-1")
bedrock_embeddings=BedrockEmbeddings(model_id="amazon.titan-embed-text-v1",client=bedrock)

# Data Ingestion
def data_ingestion():
    loader=PyPDFDirectoryLoader("pdfs")
    documents=loader.load()
    text_splitter=RecursiveCharacterTextSplitter(chunk_size=10000,chunk_overlap=1000)
    docs=text_splitter.split_documents(documents)
    return docs

# Vector embedding and vector store
def get_vector_store(docs):
    vectorstore_faiss=FAISS.from_documents(
        docs,
        bedrock_embeddings
    )
    vectorstore_faiss.save_local("faiss_index")

def get_llma2_llm():
    llm=Bedrock(model_id="meta.llama2-13b-chat-v1",client=bedrock,
                model_kwargs={"max_gen_len":512})
    return llm

prompt_template="""
Human: Use th following pieces of context to provide a concise answer to the 
question at the end but use atleast summarize with 250 words with detailed
explanations. If you don't know the answer just say that you don't know, don't try to 
make up an answer.
<context>
{context}
</context>

Question: {question}

Assistant:
"""

PROMPT=PromptTemplate(
    template=prompt_template,input_variables=["context","question"]
)



def get_response_llm(llm,vectorstore_faiss,query):
    qa=RetrievalQA.from_chain_type(
        llm=llm,
        chain_type="stuff",
        retriever=vectorstore_faiss.as_retriever(
            search_type="similarity",search_kwargs={"k":3}
        ),
        return_source_documents=True,
chain_type_kwargs={"prompt":PROMPT}
    )
    answer=qa({"query":query})
    return answer["result"]
    
def main():
    st.set_page_config("CHAT PDF")
    st.header("Chat with pdf using aws bedrock lol ;)")

    user_question=st.text_input("Ask a question from the PDF Files")
    with st.sidebar:
        st.title("Menu:")
        if st.button("Update or create vector store:"):
            with st.spinner("Processing..."):
                docs=data_ingestion()
                get_vector_store(docs)
                st.success("Done")
    if st.button("Llama2 Output"):
        with st.spinner("Processing..."):
            faiss_index=FAISS.load_local("faiss_index",bedrock_embeddings,allow_dangerous_deserialization=True)
            llm=get_llma2_llm()
            st.write(get_response_llm(llm,faiss_index,user_question))
            st.success("Done")


if __name__=="__main__":
    main()