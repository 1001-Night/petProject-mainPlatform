import { useEffect, useState } from "react";
import axios from "axios";
import "./App.css";

const API_URL = import.meta.env.VITE_API_URL || "http://localhost:8000";

function App() {
  const [notes, setNotes] = useState([]);
  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");

  async function loadNotes() {
    const response = await axios.get(`${API_URL}/notes`);
    setNotes(response.data);
  }

  async function createNote(event) {
    event.preventDefault();

    if (!title.trim() || !content.trim()) {
      return;
    }

    await axios.post(`${API_URL}/notes`, {
      title,
      content,
    });

    setTitle("");
    setContent("");
    await loadNotes();
  }

  useEffect(() => {
    loadNotes();
  }, []);

  return (
    <main className="page">
      <section className="panel">
        <div className="intro">
          <p className="eyebrow">mainPlatform</p>
          <h1>Notes App</h1>
          <p className="subtitle">
            Frontend приложение подключается к backend API, который работает с PostgreSQL.
          </p>
        </div>

        <form className="note-form" onSubmit={createNote}>
          <input
            value={title}
            onChange={(event) => setTitle(event.target.value)}
            placeholder="Заголовок"
          />
          <textarea
            value={content}
            onChange={(event) => setContent(event.target.value)}
            placeholder="Текст заметки"
          />
          <button type="submit">Добавить</button>
        </form>

        <div className="notes">
          {notes.map((note) => (
            <article className="note" key={note.id}>
              <h2>{note.title}</h2>
              <p>{note.content}</p>
            </article>
          ))}
        </div>
      </section>
    </main>
  );
}

export default App;
