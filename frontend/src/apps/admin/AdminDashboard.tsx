import React from 'react';
import { Car, Radio, UserPlus, DollarSign } from 'lucide-react';
import { Card } from '../../components/ui/Card';
import { formatTaka } from '../../theme/tokens';

export const AdminDashboard: React.FC = () => {
  const kpis = [
    {
      title: 'আজকের মোট রাইড (Total Rides)',
      value: '১,২৪৮',
      delta: '▲ ১২% গতকালের চেয়ে',
      deltaPositive: true,
      icon: <Car size={28} color="var(--navy-600)" />,
    },
    {
      title: 'সক্রিয় লাইভ রাইড (Active Rides)',
      value: '৪২',
      delta: 'লাইভ আপডেট হচ্ছে (৩০ সে)',
      deltaPositive: true,
      isLive: true,
      icon: <Radio size={28} color="var(--amber-600)" />,
    },
    {
      title: 'নতুন ড্রাইভার আবেদন (Sign-ups)',
      value: '১৮',
      delta: '৫ টি ভেরিফিকেশন বকেয়া',
      deltaPositive: false,
      icon: <UserPlus size={28} color="var(--navy-600)" />,
    },
    {
      title: 'আজকের প্লাটফর্ম আয় (Revenue)',
      value: formatTaka(48500),
      delta: '▲ ৮% বৃদ্ধি',
      deltaPositive: true,
      icon: <DollarSign size={28} color="var(--success)" />,
    },
  ];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
      <h2 style={{ fontSize: '22px', fontWeight: 600, color: 'var(--text-primary)' }}>
        অপারেশনস ড্যাশবোর্ড (Live Summary)
      </h2>

      {/* 4-Column KPI Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '16px' }}>
        {kpis.map((kpi, idx) => (
          <Card
            key={idx}
            style={{
              padding: '20px',
              borderLeft: kpi.isLive ? '4px solid var(--amber-500)' : '1px solid var(--border-default)',
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '12px' }}>
              <span style={{ fontSize: '14px', fontWeight: 500, color: 'var(--text-secondary)' }}>{kpi.title}</span>
              {kpi.icon}
            </div>

            <div className="font-num" style={{ fontSize: '32px', fontWeight: 700, color: 'var(--navy-900)' }}>
              {kpi.value}
            </div>

            <div
              style={{
                fontSize: '12px',
                fontWeight: 600,
                color: kpi.deltaPositive ? 'var(--success)' : 'var(--warning)',
                marginTop: '6px',
                display: 'flex',
                alignItems: 'center',
                gap: '4px',
              }}
            >
              {kpi.delta}
            </div>
          </Card>
        ))}
      </div>

      {/* Recent Trips Overview Table */}
      <Card style={{ padding: '0', overflow: 'hidden' }}>
        <div style={{ padding: '16px 20px', backgroundColor: 'var(--gray-50)', borderBottom: '1px solid var(--border-default)' }}>
          <h3 style={{ fontSize: '16px', fontWeight: 600, color: 'var(--text-primary)' }}>সাম্প্রতিক রাইড কার্যক্রম</h3>
        </div>

        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '14px' }}>
          <thead>
            <tr style={{ backgroundColor: 'var(--gray-50)', borderBottom: '1px solid var(--border-default)', color: 'var(--text-secondary)' }}>
              <th style={{ padding: '12px 16px' }}>রাইড আইডি</th>
              <th style={{ padding: '12px 16px' }}>যাত্রী</th>
              <th style={{ padding: '12px 16px' }}>ড্রাইভার</th>
              <th style={{ padding: '12px 16px' }}>রুট</th>
              <th style={{ padding: '12px 16px' }}>ভাড়া</th>
              <th style={{ padding: '12px 16px' }}>স্ট্যাটাস</th>
            </tr>
          </thead>
          <tbody>
            <tr style={{ borderBottom: '1px solid var(--border-default)' }}>
              <td className="font-num" style={{ padding: '14px 16px', fontWeight: 600 }}>#PTH-8839</td>
              <td style={{ padding: '14px 16px' }}>তানভীর আহমেদ</td>
              <td style={{ padding: '14px 16px' }}>মো: রফিকুল ইসলাম</td>
              <td style={{ padding: '14px 16px' }}>গুলশান ২ ➔ ধানমন্ডি ৩২</td>
              <td className="font-num" style={{ padding: '14px 16px', fontWeight: 600 }}>{formatTaka(185)}</td>
              <td style={{ padding: '14px 16px', color: 'var(--success)', fontWeight: 600 }}>চলমান (In-Trip)</td>
            </tr>
            <tr style={{ borderBottom: '1px solid var(--border-default)' }}>
              <td className="font-num" style={{ padding: '14px 16px', fontWeight: 600 }}>#PTH-8838</td>
              <td style={{ padding: '14px 16px' }}>সাবরিনা সুলতানা</td>
              <td style={{ padding: '14px 16px' }}>জহিরুল আলম</td>
              <td style={{ padding: '14px 16px' }}>মিরপুর ১০ ➔ কারওয়ান বাজার</td>
              <td className="font-num" style={{ padding: '14px 16px', fontWeight: 600 }}>{formatTaka(140)}</td>
              <td style={{ padding: '14px 16px', color: 'var(--navy-600)', fontWeight: 600 }}>সম্পন্ন (Completed)</td>
            </tr>
          </tbody>
        </table>
      </Card>
    </div>
  );
};
