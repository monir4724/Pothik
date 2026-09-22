import React, { useState } from 'react';
import { ArrowLeft, UserPlus, Trash2, ShieldAlert } from 'lucide-react';
import { Card } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';
import { InputField } from '../../components/ui/InputField';

export interface GuardiansScreenProps {
  onBack: () => void;
}

export const GuardiansScreen: React.FC<GuardiansScreenProps> = ({ onBack }) => {
  const [guardians, setGuardians] = useState([
    { id: '1', name: 'মো: শফিকুল ইসলাম (বাবা)', phone: '+880 1712-345678' },
    { id: '2', name: 'নাজমুন নাহার (স্ত্রী)', phone: '+880 1819-876543' },
  ]);

  const [newName, setNewName] = useState('');
  const [newPhone, setNewPhone] = useState('');
  const [showAdd, setShowAdd] = useState(false);

  const handleAdd = () => {
    if (!newName || !newPhone) return;
    setGuardians([...guardians, { id: Date.now().toString(), name: newName, phone: newPhone }]);
    setNewName('');
    setNewPhone('');
    setShowAdd(false);
  };

  const handleDelete = (id: string) => {
    setGuardians(guardians.filter((g) => g.id !== id));
  };

  return (
    <div style={{ padding: '16px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
      {/* App Bar */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
        <button
          onClick={onBack}
          style={{
            border: 'none',
            backgroundColor: 'transparent',
            cursor: 'pointer',
            padding: '8px',
            borderRadius: '50%',
            display: 'flex',
            alignItems: 'center',
          }}
        >
          <ArrowLeft size={24} color="var(--navy-900)" />
        </button>
        <h2 style={{ fontSize: '20px', fontWeight: 600, color: 'var(--text-primary)' }}>জরুরি অভিভাবক সেটিংস</h2>
      </div>

      <div
        style={{
          backgroundColor: 'var(--navy-50)',
          border: '1px solid var(--navy-200)',
          borderRadius: '12px',
          padding: '12px 14px',
          fontSize: '13px',
          color: 'var(--navy-900)',
          display: 'flex',
          gap: '10px',
        }}
      >
        <ShieldAlert size={20} color="var(--navy-600)" style={{ flexShrink: 0 }} />
        <span>
          SOS ট্রিগার করলে এই নম্বরগুলোতে আপনার লাইভ ট্র্যাকিং লিঙ্ক ও গাড়ির তথ্য এসএমএস এর মাধ্যমে চলে যাবে।
        </span>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
        {guardians.map((g) => (
          <Card key={g.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <div style={{ fontSize: '16px', fontWeight: 600, color: 'var(--text-primary)' }}>{g.name}</div>
              <div className="font-num" style={{ fontSize: '14px', color: 'var(--text-secondary)' }}>
                {g.phone}
              </div>
            </div>
            <button
              onClick={() => handleDelete(g.id)}
              style={{
                border: 'none',
                backgroundColor: 'transparent',
                color: 'var(--danger)',
                cursor: 'pointer',
                padding: '8px',
              }}
            >
              <Trash2 size={18} />
            </button>
          </Card>
        ))}

        {guardians.length < 3 && !showAdd && (
          <Button variant="secondary" onClick={() => setShowAdd(true)}>
            <UserPlus size={18} style={{ marginRight: '8px' }} /> নতুন অভিভাবক যোগ করুন
          </Button>
        )}

        {showAdd && (
          <Card style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            <h4 style={{ fontSize: '15px', fontWeight: 600 }}>অভিভাবক যোগ করুন</h4>
            <InputField
              label="নাম ও সম্পর্ক"
              placeholder="যেমন: মো: রফিক (ভাই)"
              value={newName}
              onChange={(e) => setNewName(e.target.value)}
            />
            <InputField
              label="ফোন নম্বর"
              placeholder="+880 1700-000000"
              value={newPhone}
              onChange={(e) => setNewPhone(e.target.value)}
            />
            <div style={{ display: 'flex', gap: '8px' }}>
              <Button variant="secondary" fullWidth onClick={() => setShowAdd(false)}>
                বাতিল
              </Button>
              <Button fullWidth onClick={handleAdd}>
                সংরক্ষণ করুন
              </Button>
            </div>
          </Card>
        )}
      </div>
    </div>
  );
};
