import { useState } from 'react';
import Navbar from '@/components/Navbar';
import HomePage from '@/pages/HomePage';
import RegisterPage from '@/pages/RegisterPage';
import ScannerPage from '@/pages/ScannerPage';
import AdminPage from '@/pages/AdminPage';

type Page =
  | 'home'
  | 'register'
  | 'entry'
  | 'check-in'
  | 'bag-drop'
  | 'security'
  | 'immigration'
  | 'gate'
  | 'boarded'
  | 'admin';

function App() {
  const [page, setPage] = useState<Page>('home');
  const navigate = (p: string) => setPage(p as Page);

  function renderPage() {
    switch (page) {
      case 'home':        return <HomePage onNavigate={navigate} />;
      case 'register':    return <RegisterPage onNavigate={navigate} />;
      case 'entry':       return <ScannerPage key="entry"       checkpoint="entry"       onNavigate={navigate} />;
      case 'check-in':    return <ScannerPage key="check-in"    checkpoint="check-in"    onNavigate={navigate} />;
      case 'bag-drop':    return <ScannerPage key="bag-drop"    checkpoint="bag-drop"    onNavigate={navigate} />;
      case 'security':    return <ScannerPage key="security"    checkpoint="security"    onNavigate={navigate} />;
      case 'immigration': return <ScannerPage key="immigration" checkpoint="immigration" onNavigate={navigate} />;
      case 'gate':        return <ScannerPage key="gate"        checkpoint="gate"        onNavigate={navigate} />;
      case 'boarded':     return <ScannerPage key="boarded"     checkpoint="boarded"     onNavigate={navigate} />;
      case 'admin':       return <AdminPage />;
      default:            return <HomePage onNavigate={navigate} />;
    }
  }

  return (
    <div className="min-h-screen bg-slate-50">
      <Navbar currentPage={page} onNavigate={navigate} />
      {renderPage()}
    </div>
  );
}

export default App;
